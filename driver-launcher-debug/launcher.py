from builtins import print, open, repr
import argparse
import yaml

parser = argparse.ArgumentParser(description="")
parser.add_argument("--launcher_yaml", type=str, required=True, help="")
args = parser.parse_args()
launcher_yaml = args.launcher_yaml

print(launcher_yaml)
with open(launcher_yaml, 'r') as f:
    lch = f.read()

launcher = yaml.safe_load(lch)

with open('output_launcher.env', 'w') as l:
    commands = launcher['spec']['containers'][1]['command']
    args = launcher['spec']['containers'][1]['args']
    l.write(f"--pipeline_name={commands[commands.index('--pipeline_name')+1]}\n")
    l.write(f"--pod_name={launcher['metadata']['name']}\n")
    l.write(f"--pod_uid={launcher['metadata']['uid']}\n")
    l.write(f"--run_id={commands[commands.index('--run_id')+1]}\n")
    l.write(f"--execution_id={commands[commands.index('--execution_id')+1]}\n")
    l.write("--mlmd_server_address=localhost\n")
    l.write("--mlmd_server_port=8080\n")

    l.write("--executor_input\n")
    exec_json = commands[commands.index('--executor_input')+1]
    exec_json = exec_json.replace('"', '\\"').replace('\n', '\\n')
    l.write(f"{exec_json}\n")

    l.write("--component_spec\n")
    component_spec = commands[commands.index('--component_spec')+1]
    component_spec = component_spec.replace('"', '\\"').replace('\n', '\\n')
    l.write(f"{component_spec}\n")

    l.write("--\n")
    l.write("sh\n")
    l.write("'-c'\n")
    l.write("print(\"hello\")\n")
    l.write("--executor_input\n")
    l.write(f"{args[args.index('--executor_input')+1]}\n")
    l.write("--function_to_execute\n")
    l.write(f"{args[args.index('--function_to_execute')+1]}\n")



