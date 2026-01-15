# GitHub Pages Documentation Setup

This repository is configured to automatically build and deploy documentation to GitHub Pages using GitHub Actions.

## Setup Instructions

To enable GitHub Pages for this repository, follow these steps:

### 1. Enable GitHub Pages

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Pages**
3. Under **Source**, select **GitHub Actions** as the deployment source
4. Save the changes

### 2. Workflow Trigger

The documentation will be automatically built and deployed when:
- Code is pushed to the `master` branch
- The workflow is manually triggered from the **Actions** tab

### 3. Accessing the Documentation

Once deployed, the documentation will be available at:
```
https://<username>.github.io/<repository-name>/
```

For the realm-swift repository, it will be:
```
https://realm.github.io/realm-swift/
```

The documentation includes:
- **Swift API Documentation**: Available at `/swift/`
- **Objective-C API Documentation**: Available at `/objc/`

## Workflow Overview

The GitHub Actions workflow (`.github/workflows/deploy-docs.yml`) performs the following steps:

1. **Checkout**: Fetches the repository code
2. **Setup Ruby**: Installs Ruby and dependencies from the Gemfile (including Jazzy)
3. **Build Documentation**: 
   - Builds Swift documentation using `bundle exec sh build.sh docs swift`
   - Builds Objective-C documentation using `bundle exec sh build.sh docs objc`
4. **Prepare Deployment**: Organizes documentation into a `_site` directory structure
5. **Deploy**: Uploads and publishes the documentation to GitHub Pages

## Local Development

To build the documentation locally:

```bash
# Install dependencies
bundle install

# Build Swift documentation
sh build.sh docs swift

# Build Objective-C documentation  
sh build.sh docs objc
```

The output will be in:
- `docs/swift_output/` - Swift API documentation
- `docs/objc_output/` - Objective-C API documentation

## Requirements

- **macOS runner**: Required for building the documentation (uses Xcode tools)
- **Ruby**: Installed via `ruby/setup-ruby` action
- **Jazzy**: Installed via Bundler from the Gemfile
- **GitHub Pages permissions**: Configured in the workflow file

## Customization

To customize the documentation:

- Edit `docs/custom_head.html` to modify the HTML head section
- Modify the workflow file to change build behavior
- Edit the index page generation in the workflow to customize the landing page

## Troubleshooting

If the deployment fails:

1. Check the **Actions** tab for error logs
2. Ensure GitHub Pages is enabled in repository settings
3. Verify that the repository has the necessary permissions
4. Check that all Ruby dependencies are properly specified in the Gemfile

## Manual Deployment

To manually trigger a documentation deployment:

1. Go to the **Actions** tab in the repository
2. Select the **Deploy Documentation** workflow
3. Click **Run workflow**
4. Select the branch (usually `master`)
5. Click the green **Run workflow** button
