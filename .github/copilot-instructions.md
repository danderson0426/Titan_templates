# Titan Templates Repository

Titan Templates is a minimal template repository that serves as a starting point for various types of development projects. The repository currently contains only a basic README.md file and can be used as a foundation for Node.js, Python, Java, .NET, Go, or other development projects.

**Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

## Working Effectively

### Repository Structure
The repository is currently minimal with the following structure:
```
/home/runner/work/Titan_templates/Titan_templates/
├── .git/
├── .github/
│   └── copilot-instructions.md (this file)
└── README.md
```

### Available Development Tools
The following development tools are pre-installed and verified working:
- **Node.js**: v20.19.5 with npm 10.8.2
- **Python**: 3.12.3 with pip 24.0
- **Go**: go1.24.7 linux/amd64
- **Java**: OpenJDK 17.0.16
- **.NET**: 8.0.119
- **Git**: Configured with copilot-swe-agent[bot] user

### Basic Repository Operations
- Always work from the repository root: `/home/runner/work/Titan_templates/Titan_templates`
- Check current status: `git --no-pager status`
- View repository structure: `ls -la`
- All changes should be committed using the report_progress tool, not direct git commands

## Project Initialization

### Node.js Projects
To initialize a Node.js project:
```bash
npm init -y     # Takes <1 second
npm install [package-name]  # Takes ~3 seconds for simple packages like express
```
**Timeout recommendation**: 120 seconds for npm install operations.

### Python Projects
To initialize a Python project:
```bash
python3 -m venv venv  # Takes ~3 seconds
source venv/bin/activate
pip install [package-name]  # May fail due to network timeouts to PyPI
```
**Timeout recommendation**: 300 seconds for pip install operations.
**WARNING**: pip install may fail with "Read timed out" errors due to network limitations. Document such failures rather than treating them as instruction errors.

### Go Projects
To initialize a Go project:
```bash
go mod init [module-name]  # Takes <1 second
# Create main.go with proper Go syntax
go run main.go  # Takes ~0.1 seconds for execution
go build       # Takes ~0.1 seconds for compilation
```
**Timeout recommendation**: 60 seconds for go build operations.

### Java Projects
To work with Java:
```bash
# Create .java files
javac *.java    # Takes ~0.4 seconds for compilation
java ClassName  # Takes ~0.03 seconds for execution
```
**Timeout recommendation**: 60 seconds for javac compilation.

### .NET Projects
To initialize a .NET project:
```bash
dotnet new console -n ProjectName  # Takes <1 second
cd ProjectName
dotnet build    # Takes ~1.5 seconds for simple projects
dotnet run      # Takes ~1.3 seconds to execute
```
**Timeout recommendation**: 300 seconds for dotnet build operations.
**NEVER CANCEL**: .NET builds may take longer for complex projects with dependencies.

## Validation and Testing

### Manual Validation Requirements
After making changes to any project type:
1. **Always test basic functionality** - don't just start/stop applications
2. **For Node.js**: Test with `node app.js` and verify expected output
3. **For Python**: Test with `python3 script.py` and verify functionality
4. **For Go**: Test with `go run main.go` and verify output
5. **For Java**: Test compilation with `javac` and execution with `java`
6. **For .NET**: Test with `dotnet run` and verify console output

### Common Validation Commands
- **Directory listing**: `ls -la` (immediate)
- **File viewing**: `cat filename` (immediate) 
- **Git status**: `git --no-pager status` (immediate)
- **Basic syntax check**: Language-specific linting tools when available

## Build and Test Timing Expectations

### Quick Operations (< 5 seconds)
- File creation and editing
- Git status checks
- Directory navigation
- Simple script execution

### Medium Operations (5-30 seconds)
- Package installations (npm, pip simple packages)
- Basic compilation (Go, Java small projects)
- Git operations

### Long Operations (30 seconds - 5 minutes)
- Complex package installations
- .NET project builds with dependencies
- Large project compilation

**CRITICAL**: Always set appropriate timeouts:
- **Quick operations**: Default timeout (120 seconds)
- **Package installations**: 300 seconds minimum
- **.NET builds**: 300 seconds minimum
- **NEVER CANCEL** long-running operations without waiting for completion

## Development Workflows

### Adding New Project Types
When setting up a new project type in this template:
1. Create appropriate directory structure
2. Add project-specific configuration files (package.json, requirements.txt, etc.)
3. Test initialization commands thoroughly
4. Update these instructions with validated commands and timing
5. Always include specific validation scenarios

### Working with Dependencies
- **Always test dependency installation** before documenting commands
- **Verify package availability** and installation success
- **Document expected installation times** based on actual testing
- **Include fallback options** when primary installation methods fail

### Version Control Best Practices
- Use `git --no-pager` for all git commands to avoid pager issues
- Commit changes frequently using report_progress tool
- Never use `git reset` or `git rebase` as force push is not available
- Check branch status regularly: `git --no-pager branch -a`

## Common Tasks Reference

### Repository Root Listing
```
ls -la /home/runner/work/Titan_templates/Titan_templates
total 20
drwxr-xr-x 4 runner runner 4096 [timestamp] .
drwxr-xr-x 3 runner runner 4096 [timestamp] ..
drwxrwxr-x 7 runner runner 4096 [timestamp] .git
drwxrwxr-x 2 runner runner 4096 [timestamp] .github
-rw-rw-r-- 1 runner runner   17 [timestamp] README.md
```

### README.md Content
```
cat README.md
# Titan_templates
```

### Available Branches
Current working branch: `copilot/fix-2`
Available branches include: `main`, `copilot/fix-2`

### Tool Version Reference
- Node.js: v20.19.5
- npm: 10.8.2
- Python: 3.12.3
- pip: 24.0
- Go: go1.24.7
- Java: OpenJDK 17.0.16
- .NET: 8.0.119

## Troubleshooting

### Common Issues
1. **Permission errors**: Ensure you're working in the correct repository directory
2. **Package installation failures**: Check network connectivity and retry with longer timeouts
3. **Build failures**: Verify all dependencies are installed and tools are available
4. **Git operation issues**: Use report_progress tool instead of direct git commands
5. **Network timeouts**: pip installs may fail with "Read timed out" errors - this is a network limitation, not an instruction error

### When Instructions Don't Work
If any command in these instructions fails:
1. Document the failure in your work
2. Try alternative approaches with different tools
3. Verify the environment hasn't changed
4. Only document commands as "does not work" after exhausting all alternatives
5. Always update these instructions with working alternatives when found

**Remember**: These instructions are based on actual testing and validation. Always follow them first before exploring alternatives.