# Titan Templates Repository

ALWAYS follow these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Repository Overview
Titan_templates is a template repository designed for creating and managing project templates. This is a minimal repository structure that serves as a foundation for building various project templates.

## Working Effectively

### Initial Setup and Navigation
- Clone and navigate to repository: `cd /home/runner/work/Titan_templates/Titan_templates`
- Check repository status: `git status` (takes <1 second)
- List repository contents: `ls -la` (takes <1 second) 
- View current branch: `git branch -a` (takes <1 second)
- Check recent commits: `git log --oneline -5` (takes <1 second)

### Repository Structure
Current minimal structure:
```
.
├── README.md           # Main repository documentation
├── .github/           # GitHub configuration directory
│   └── copilot-instructions.md  # This file
└── .git/              # Git repository data
```

### Key Repository Information
- **Type**: Template repository for project scaffolding
- **Main files**: README.md (17 bytes, contains "# Titan_templates")
- **Build requirements**: None currently - this is a template repository
- **Dependencies**: None currently
- **Testing**: No automated tests (template repository)

## Template Development Workflow

### Adding New Templates
1. Create template directory structure:
   ```bash
   mkdir -p templates/[template-name]
   cd templates/[template-name]
   ```

2. Add template files:
   ```bash
   # Example for a basic project template
   touch index.html
   touch style.css
   touch script.js
   touch README.md
   ```

3. Validate template structure:
   ```bash
   find templates/ -type f | sort
   ls -la templates/[template-name]/
   ```

### File Operations (All operations take <1 second)
- **Read files**: `cat README.md`
- **Find markdown files**: `find . -name "*.md"`
- **Copy template files**: `cp source_file destination_file`
- **Create directories**: `mkdir -p path/to/directory`
- **List contents**: `ls -la [directory]`

### Repository Maintenance
- **Check repository status**: `git status` 
- **View changes**: `git diff`
- **Stage files**: `git add .`
- **View commit history**: `git log --oneline -10`
- **Check remote branches**: `git branch -r`

## Validation Steps

### Before Making Changes
Always run these validation steps (total time: <5 seconds):
```bash
# Verify repository structure
ls -la
find . -name "*.md" | wc -l
git status

# Check that basic operations work
cat README.md
git log --oneline -3
```

### After Making Changes
Always validate changes with these steps:
```bash
# Verify file structure
ls -la
find . -type f | grep -v ".git" | sort

# Check git status and differences
git status
git diff

# Validate any new template files can be read
find templates/ -type f -exec file {} \; 2>/dev/null || echo "No templates directory yet"
```

### Manual Testing for Templates
When adding or modifying templates:
1. **Test template creation**: Create a new directory and copy template files
2. **Verify file permissions**: Ensure template files are readable (`ls -la template_files`)
3. **Test template usage**: Copy template to a test directory and verify it works
4. **Validate documentation**: Ensure README.md and any template docs are accurate

## Common Tasks

### Repository Exploration
The following are outputs from frequently run commands to save time:

#### Current repository root listing
```
$ ls -la
total 20
drwxr-xr-x 4 runner runner 4096 [timestamp] .
drwxr-xr-x 3 runner runner 4096 [timestamp] ..
drwxrwxr-x 7 runner runner 4096 [timestamp] .git
drwxrwxr-x 2 runner runner 4096 [timestamp] .github
-rw-rw-r-- 1 runner runner   17 [timestamp] README.md
```

#### Current README.md content
```
$ cat README.md
# Titan_templates
```

#### Git repository status
```
$ git status
On branch copilot/fix-4
Your branch is up to date with 'origin/copilot/fix-4'.
nothing to commit, working tree clean
```

### Template Creation Examples
For common template types:

#### Basic Web Template
```bash
mkdir -p templates/basic-web
cd templates/basic-web
cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head><title>{{PROJECT_NAME}}</title></head>
<body><h1>{{PROJECT_NAME}}</h1></body>
</html>
EOF
```

#### Basic README Template
```bash
mkdir -p templates/readme
cd templates/readme
cat > README.md << 'EOF'
# {{PROJECT_NAME}}

## Description
{{PROJECT_DESCRIPTION}}

## Usage
{{USAGE_INSTRUCTIONS}}
EOF
```

## Performance Notes
- All basic file operations complete in under 1 second
- Git operations are very fast (< 1 second) due to minimal repository size
- No build processes - this is a template repository
- No test suite - validation is manual through file operations

## Limitations and Considerations
- **No build system**: This is a template repository, not a buildable project
- **No automated testing**: Validation is through manual file operations
- **No dependencies**: Repository is intentionally minimal
- **Template placeholders**: Use `{{VARIABLE_NAME}}` format for template substitution
- **File permissions**: Ensure template files maintain appropriate permissions when copied

## When Instructions Are Insufficient
If these instructions don't cover your specific need:
1. Search the repository for existing examples: `find . -name "*example*" -o -name "*template*"`
2. Check for configuration files: `find . -name "*.json" -o -name "*.yml" -o -name "*.yaml"`
3. Look for documentation: `find . -name "*.md" | xargs grep -l "keyword"`
4. Examine git history: `git log --oneline --all`

Always prefer using the validated commands above before running new bash commands or searches.