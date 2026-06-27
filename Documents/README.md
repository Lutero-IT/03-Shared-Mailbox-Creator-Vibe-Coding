## Module 1: Test-DepartmentName.ps1

### Overview
A function responsible for input validation by matching the passed department 
name against enterprise naming conventions using regular expressions.

### Architectural Decisions & Guardrails
* **Defensive Input Handling:** Utilizes `[string]::IsNullOrWhiteSpace()` to seamlessly intercept null values, empty strings, or blank spaces, making the function fully resilient during remote SSH execution.
* **Regex Architecture:** Implements the pattern `^[a-zA-Z0-9]([a-zA-Z0-9-_]*[a-zA-Z0-9])?$` to restrict characters to alphanumeric formats while safeguarding structural integrity (preventing leading/trailing special characters).
* **Graceful Interruption:** Captures 'c' or 'cancel' tokens to cleanly return `$null`, allowing parent orchestrators to handle user abort sequences safely.