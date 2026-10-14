# Preparation Assignment for the Next Session

In the next session, you will check the response from a web page and put the result and date/time into a report. You will run this process in your own repository. Prepare the two files it needs in your own Codespace. This should take about 10 minutes. There is nothing to submit.

## What to Prepare

Create the following two files in a folder named `pre_day2`.

- `pre_day2/template.md` — the report template
- `pre_day2/generate.sh` — the report generator that uses the template

The file contents are provided further down this page. You will read and run them in the next session. For now, you only need to prepare them.

## What to Do

1. Open the Codespace you used today. If its tab is still open, return to it. If you closed it, open your repository page on GitHub and select `Codespaces` from `Code`, as you did today. The Codespace you created today will appear in the list; click it. Do not create a new one.
2. In the file list, create a new file named `pre_day2/template.md`. The next section explains how.
3. Copy and paste the contents of the "template.md" block below, and save the file as you did today.
4. Create and save `pre_day2/generate.sh` in the same way.
5. Open both files and compare their contents with the blocks on this page.

For this preparation, you can stay on master without creating a branch. You will commit the files in the next session.

## How to Create a New File (an Operation Not Covered in Today's Practice)

1. Right-click the row with your repository name at the top of the file list (it is shown in uppercase).
2. Select `New File...` from the menu that appears. A field for entering the name will open.
3. Enter `pre_day2/template.md` and press Enter. This creates both the `pre_day2` folder and the file inside it, and opens an empty editor.

If your screen looks different, look for the new-file option in the file list. You can also open the same menu by right-clicking the empty space below the listed files. The editor in Codespace is called VS Code. Official interface guide: [User Interface — Explorer (VS Code Docs)](https://code.visualstudio.com/docs/editing/getting-started/userinterface#_explorer-view)

## Contents to Paste

Paste only the contents of each block. Do not include the file name or the symbols surrounding the block. Do not paste them into the terminal. You will not run them this time.

### template.md

```markdown
# Web Page Check Report

Target: https://example.com/
Checked at (UTC): {{CHECKED_AT}}
HTTP status: {{HTTP_STATUS}}

This report is generated from the template and the check results.
```

### generate.sh

```sh
#!/bin/sh

# This script creates a report from the results of checking a web page.
# The #! on the first line specifies that the contents should run using a program called sh.
# Text from # to the end of a line is a comment and is not executed.

# Stop immediately if an error occurs (-e).
# Also stop if an unset value is used (-u).
set -eu

# Move to the folder containing this script.
# $0 is the location of this file; dirname extracts just the folder name from it.
# This lets the script read the neighboring template.md in the same way, wherever it is run from.
cd "$(dirname "$0")"

# case selects what to do based on the number of arguments added when running the script.
# $# is the number of arguments added.
case "$#" in
  # 0 means the script was run without any arguments.
  0)
    # [1] Access the web page and store the HTTP status in http_status.
    #     Treat failures as errors, stop after 30 seconds, and do not save the body.
    http_status=$(curl --fail --silent --show-error --location --max-time 30 \
      --output /dev/null --write-out '%{http_code}' https://example.com/)

    # [2] Store the date and time of the check in checked_at, using UTC.
    checked_at=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

    # [3] Replace the two placeholders in template.md with the values above and write report.md.
    #     Using | as the delimiter prevents / characters in the values from breaking the command.
    sed -e "s|{{CHECKED_AT}}|$checked_at|g" \
        -e "s|{{HTTP_STATUS}}|$http_status|g" template.md > report.md

    printf '%s\n' 'Generated report.md.'
    # ;; ends the processing for this case.
    ;;

  # 1 means the script was run with one argument.
  1)
    # $1 is the first argument added when running the script.
    if [ "$1" != "setup-actions" ]; then
      printf '%s\n' 'Usage: ./generate.sh or ./generate.sh setup-actions' >&2
      exit 2
    fi
    # Create the folder for the automated-run configuration. Reuse it if it already exists.
    mkdir -p ../.github/workflows
    # Write the following lines to a file exactly as they are, up to but not including WORKFLOW.
    cat > ../.github/workflows/update-report.yml <<'WORKFLOW'
name: Update report

on:
  push:
    branches: [master]
    paths:
      - pre_day2/template.md
      - pre_day2/generate.sh
      - .github/workflows/update-report.yml
  workflow_dispatch:

permissions:
  contents: write

jobs:
  update-report:
    runs-on: ubuntu-latest
    steps:
      - name: Check out the repository
        uses: actions/checkout@v7

      - name: Check required tools
        run: |
          command -v sh
          command -v sed
          command -v date
          command -v curl

      - name: Generate the report
        run: |
          chmod +x pre_day2/generate.sh
          ./pre_day2/generate.sh

      - name: Commit the changed report
        run: |
          if [ -z "$(git status --porcelain -- pre_day2/report.md)" ]; then
            echo "No changes to report.md."
            exit 0
          fi
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git add pre_day2/report.md
          git commit -m "chore: update report"
          git push
WORKFLOW
    # Display a message confirming that the file was written.
    printf '%s\n' 'Created .github/workflows/update-report.yml.'
    ;;

  # * covers any case that matches neither of the cases above.
  *)
    printf '%s\n' 'Usage: ./generate.sh or ./generate.sh setup-actions' >&2
    exit 2
    ;;
# esac ends the entire case statement.
esac
```

## When You Are Done

- The file list contains two files inside `pre_day2`, and opening them shows the same contents as the blocks on this page.
- When you repeat the operation from today's practice that showed the names of changed files, `pre_day2/` appears. These are new files, so they appear under a different heading from today's files, but seeing `pre_day2/` is enough. They are saved but have not yet been committed. You will commit them in the next session, so you are done for now.
- You will start from this Codespace next time. Keep it; do not delete it. If the Codespace has been deleted, create a new one using the same steps as today, then recreate both files using the steps on this page.
