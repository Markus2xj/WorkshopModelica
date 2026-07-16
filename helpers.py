from fmpy import read_model_description, extract, dump
from fmpy.fmi2 import FMU2Slave
import os
import shutil
import math
import uuid

def build_variable_maps(model_description):
    """
    Build helper dictionaries:
    - vrs: variable name -> value reference
    - var_info: variable name -> model variable object
    """
    vrs = {}
    var_info = {}

    for variable in model_description.modelVariables:
        vrs[variable.name] = variable.valueReference
        var_info[variable.name] = variable

    return vrs, var_info


def set_fmu_parameters(fmu, parameters, vrs, var_info, strict=True):
    """
    Set FMU parameters during initialization.

    Parameters
    ----------
    fmu : FMU2Slave
    parameters : dict
        Example:
        {
            'vR1': 0.0013,
            'vR2': 0.00068,
            'Tsetpoint': 20.0
        }
    vrs : dict
        variable name -> value reference
    var_info : dict
        variable name -> variable object
    strict : bool
        If True, raise an error when a parameter is not found.
        If False, print a warning and continue.
    """
    if parameters is None:
        return

    for name, value in parameters.items():
        if name not in vrs:
            msg = f"Parameter '{name}' not found in FMU."
            if strict:
                raise KeyError(msg)
            else:
                print(f"Warning: {msg}")
                continue

        var = var_info[name]
        vr = vrs[name]

        # We focus on Real parameters, but support common scalar types as well.
        try:
            if var.type == 'Real':
                fmu.setReal([vr], [float(value)])
            elif var.type == 'Integer' or var.type == 'Enumeration':
                fmu.setInteger([vr], [int(value)])
            elif var.type == 'Boolean':
                fmu.setBoolean([vr], [bool(value)])
            elif var.type == 'String':
                fmu.setString([vr], [str(value)])
            else:
                msg = f"Unsupported type '{var.type}' for parameter '{name}'."
                if strict:
                    raise TypeError(msg)
                else:
                    print(f"Warning: {msg}")
        except Exception as e:
            raise RuntimeError(f"Failed setting parameter '{name}' to '{value}': {e}") from e


def close_fmu(fmu, unzipdir):
    """
    Clean up FMU instance and extracted directory.
    """
    try:
        fmu.terminate()
    except Exception:
        pass

    try:
        fmu.freeInstance()
    except Exception:
        pass

    try:
        if unzipdir and os.path.isdir(unzipdir):
            shutil.rmtree(unzipdir, ignore_errors=True)
    except Exception:
        pass


def build_instance_name(prefix='instance'):
    """
    Create a unique FMI instance name per run.
    """
    return f"{prefix}_{uuid.uuid4().hex}"


def build_fmu_context(filepath, validate=True):
    """
    Read the static FMU metadata once so batch runs don't repeatedly invoke
    XML schema validation after every single simulation.
    """
    model_description = read_model_description(filepath, validate=validate)
    vrs, var_info = build_variable_maps(model_description)

    if model_description.coSimulation is None:
        raise ValueError("Only co-simulation FMUs are supported.")

    return {
        'model_description': model_description,
        'vrs': vrs,
        'var_info': var_info,
    }


def load_fmu(
    filepath,
    start_time,
    parameters=None,
    printInfo=False,
    strict_parameters=True,
    fmu_context=None,
    validate_model_description=False
):
    if fmu_context is None:
        fmu_context = build_fmu_context(
            filepath=filepath,
            validate=validate_model_description
        )

    model_description = fmu_context['model_description']
    vrs = fmu_context['vrs']
    var_info = fmu_context['var_info']

    unzipdir = None
    fmu = None

    try:
        unzipdir = extract(filepath)

        fmu = FMU2Slave(
            guid=model_description.guid,
            unzipDirectory=unzipdir,
            modelIdentifier=model_description.coSimulation.modelIdentifier,
            instanceName=build_instance_name()
        )

        fmu.instantiate(loggingOn=False)
        fmu.setupExperiment(startTime=start_time)
        fmu.enterInitializationMode()

        if parameters is not None:
            set_fmu_parameters(
                fmu=fmu,
                parameters=parameters,
                vrs=vrs,
                var_info=var_info,
                strict=strict_parameters
            )

        fmu.exitInitializationMode()
    except Exception:
        close_fmu(fmu, unzipdir)
        raise

    if printInfo:
        dump(filepath)
        print(vrs)
        print(model_description)

    return fmu, vrs, var_info, unzipdir


def discover_variables(filepath):
    """Print inputs / outputs so you can fix the candidate names above."""
    md = read_model_description(filepath)
    inputs, outputs, locals_ = [], [], []
    for v in md.modelVariables:
        if v.causality == "input":
            inputs.append((v.name, v.type))
        elif v.causality == "output":
            outputs.append((v.name, v.type))
        else:
            locals_.append(v.name)
    print("=== FMU inputs (settable) ===")
    for n, t in inputs:
        print(f"  {n}  [{t}]")
    print("=== FMU outputs ===")
    for n, t in outputs:
        print(f"  {n}  [{t}]")
    print(f"(+{len(locals_)} local variables, readable by name)")
    return md


def resolve(vrs, candidates, label, required=True):
    """Return the first candidate name present in the FMU's variable map."""
    for name in candidates:
        if name in vrs:
            return name
    if required:
        raise KeyError(
            f"None of the candidate names for '{label}' were found in the FMU.\n"
            f"  Tried: {candidates}\n"
            f"  Run discover_variables() and update the *_CANDIDATES lists."
        )
    print(f"Warning: '{label}' not found ({candidates}); it will be skipped.")
    return None


def set_input(fmu, vrs, var_info, name, value):
    """Set an FMU input mid-run, dispatching on the declared variable type."""
    vr = vrs[name]
    vtype = var_info[name].type
    if vtype == "Boolean":
        fmu.setBoolean([vr], [bool(value)])
    elif vtype in ("Real",):
        fmu.setReal([vr], [float(value)])
    elif vtype in ("Integer", "Enumeration"):
        fmu.setInteger([vr], [int(value)])
    else:
        raise TypeError(f"Cannot set input '{name}' of type '{vtype}'.")


def to_celsius(value):
    """Heuristic: treat readings above 100 as Kelvin and convert."""
    return value - 273.15 if value > 100.0 else value



