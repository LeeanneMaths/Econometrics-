# Deploy This App As A Public Link

Use this guide to create a stable web link for supervisors or reviewers.

## What Is Included

This folder is now cloud-ready:

- `app.py`: the Streamlit app.
- `requirements.txt`: Python dependencies.
- `data/`: the bundled default CSV files.

The app no longer depends on a local `D:` drive path when deployed.

## Recommended Deployment: Streamlit Community Cloud

1. Create or open a GitHub account.
2. Create a new GitHub repository, for example:

```text
education-data-econometrics-explorer
```

3. Upload every file and folder from this folder to the repository:

```text
app.py
requirements.txt
README.md
DEPLOY.md
data/
```

4. Go to:

```text
https://share.streamlit.io/
```

5. Sign in with GitHub.
6. Click `New app`.
7. Select the repository you created.
8. Set the main file path to:

```text
app.py
```

9. Click `Deploy`.

After deployment, Streamlit will give you a public link ending in:

```text
.streamlit.app
```

That is the link you can send to supervisors.

## Before Sending The Link

Open the link yourself and check:

1. The title says `Education Data Econometrics Explorer`.
2. The current dataset line shows the full CSV filename.
3. The `Overview` tab loads without errors.
4. The `Trends and Gaps` tab draws a chart.
5. The `Regression Model` tab produces a table.

## Important Note

The uploaded GitHub repository should not contain private or restricted data. Only upload data that you are allowed to share.
