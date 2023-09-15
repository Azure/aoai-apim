# imports
from pathlib import Path
from azureml.core import Workspace, ScriptRunConfig, Experiment, Environment, Dataset

# constants
compute_name = "cpu-cluster"  # use "local" for local execution
source_dir = "src"
entry_script = "train.py"
environment_name = "myenv-template"
environment_file = "requirements.txt"
experiment_name = "template-workflow-base"
data_uri = "https://azuremlexamples.blob.core.windows.net/datasets/iris.csv"

# convert to relative paths
prefix = Path(__file__).parent
source_dir = str(prefix.joinpath(source_dir))
environment_file = str(prefix.joinpath(environment_file))

# get workspace
ws = Workspace.from_config()

# create dataset
ds = Dataset.File.from_files(data_uri)

# create environment
env = Environment.from_pip_requirements(environment_name, environment_file)

# setup entry script arguments
args = ["--data-dir", ds.as_mount()]

# create a job configuration
src = ScriptRunConfig(
    source_directory=source_dir,
    script=entry_script,
    arguments=args,
    environment=env,
    compute_target=compute_name,
)

# run the job
run = Experiment(ws, experiment_name).submit(src)
run.wait_for_completion(show_output=True)
