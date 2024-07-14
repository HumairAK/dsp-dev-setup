from builtins import print, open, repr
import argparse
import yaml

parser = argparse.ArgumentParser(description="")
parser.add_argument("--driver_yaml", type=str, required=True, help="")
args = parser.parse_args()
driver_yaml = args.driver_yaml

print(driver_yaml)
with open(driver_yaml, 'r') as f:
    lch = f.read()

driver = yaml.safe_load(lch)

def write_json(param, writer):
    spec = args[args.index(f"--{param}")+1]
    spec = spec.replace('"', '\\"').replace('\n', '\\n')
    if not spec:
        writer.write(f"--{param}=\"\"\n")
    else:
        writer.write(f"--{param}\n")

        writer.write(f"{spec}\n")

with open('output_driver.env', 'w') as l:
    annotations = driver['metadata']['annotations']
    commands = driver['spec']['containers'][1]['command']
    args = driver['spec']['containers'][1]['args']


    type = "ROOT_DRIVER" if "root-driver" in annotations['workflows.argoproj.io/node-name'] else "CONTAINER"
    l.write(f"--type={type}\n")

    l.write(f"--pipeline_name={args[args.index('--pipeline_name')+1]}\n")
    l.write(f"--run_id={args[args.index('--run_id')+1]}\n")
    l.write(f"--dag_execution_id={args[args.index('--dag_execution_id')+1]}\n")

    write_json("component", l)
    write_json("task", l)

    if type == "ROOT_DRIVER":
        write_json("runtime_config", l)
        l.write(f"--iteration_count_path={args[args.index('--iteration_count_path')+1]}\n")
        l.write(f"--execution_id_path={args[args.index('--execution_id_path')+1]}\n")

    else:
        write_json("container", l)
        l.write(f"--cached_decision_path={args[args.index('--cached_decision_path')+1]}\n")
        l.write(f"--pod_spec_patch_path={args[args.index('--pod_spec_patch_path')+1]}\n")
        l.write(f"--kubernetes_config={args[args.index('--kubernetes_config')+1]}\n")

    l.write(f"--iteration_index={args[args.index('--iteration_index')+1]}\n")
    l.write(f"--condition_path={args[args.index('--condition_path')+1]}\n")
    l.write(f"--mlPipelineServiceTLSEnabled={args[args.index('--mlPipelineServiceTLSEnabled')+1]}\n")
