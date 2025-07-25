# GitHub Actions Workflows

This directory contains GitHub Actions workflows for CI/CD, testing, linting, and security scanning.

## Workflows

### 1. CI/CD Pipeline (`ci.yml`)
**Triggers:** Push to master branch, Pull requests

**Jobs:**
- **dotnet-test**: Builds and tests the .NET 8 application with code coverage
- **dotnet-lint**: Runs code formatting checks and static analysis
- **terraform-validate**: Validates Terraform configuration with TFLint
- **shell-script-validation**: Validates shell scripts with ShellCheck
- **security-scan**: Runs Trivy vulnerability scanning

### 2. Dependency Security Scan (`dependency-scan.yml`)
**Triggers:** Scheduled (Mondays 9 AM UTC), Push to master, Manual dispatch

**Jobs:**
- **dotnet-security**: Scans for outdated and vulnerable .NET packages
- **dependency-review**: Reviews dependency changes in PRs
- **terraform-security**: Runs Checkov and tfsec security scanning on Terraform

### 3. CodeQL Analysis (`codeql.yml`)
**Triggers:** Push to master, PRs to master, Scheduled (Sundays 5:21 PM UTC)

**Jobs:**
- **analyze**: Performs advanced security analysis on C# code

## Configuration Files

- `.editorconfig`: Code formatting rules for consistent style
- `.shellcheckrc`: ShellCheck configuration for shell script validation
- `terraform/.tflint.hcl`: TFLint configuration for Terraform validation

## Features

✅ **Testing**
- Unit tests with xUnit
- Integration tests with ASP.NET Core Test Host
- Code coverage reporting with Codecov

✅ **Linting & Formatting**
- .NET code formatting with `dotnet format`
- Terraform formatting validation
- Shell script validation with ShellCheck

✅ **Security Scanning**
- Dependency vulnerability scanning
- Static code analysis with CodeQL
- Infrastructure security with Checkov and tfsec
- Container/filesystem scanning with Trivy

✅ **Quality Gates**
- Build failures on warnings
- Format validation
- Test failures block deployment
- Security issues reported to GitHub Security tab

## Local Development

To run these checks locally:

```bash
# .NET formatting and tests
dotnet format --verify-no-changes
dotnet test --collect:"XPlat Code Coverage"

# Terraform validation
cd terraform
terraform fmt -check
terraform validate
tflint

# Shell script validation
shellcheck scripts/*.sh
```

## Status Badges

Add these badges to your main README.md:

```markdown
[![CI/CD Pipeline](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/ci.yml)
[![Security Scan](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/dependency-scan.yml/badge.svg)](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/dependency-scan.yml)
[![CodeQL](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/codeql.yml/badge.svg)](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/codeql.yml)
```