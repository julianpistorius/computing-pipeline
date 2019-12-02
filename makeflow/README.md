# Agriculture Processing Pipeline: Makeflow

Testing redesigned Makeflow for Ag Pipeline

To test:

1. Copy `makeflow/jx-args.json.example` to `makeflow/jx-args.json` and modify to suit
2. Run the following command from the project directory (wherever you checked out `agp_test`):

```bash
makeflow --jx --jx-args=makeflow/jx-args.json makeflow/combined_workflow.jx
```

Check that the output in `output/tifs` looks right

To clean intermediate & final outputs of workflow:

```bash
makeflow -c --jx --jx-args=makeflow/jx-args.json makeflow/combined_workflow.jx
```

This assumes you have a recent version of Makeflow installed and working.

