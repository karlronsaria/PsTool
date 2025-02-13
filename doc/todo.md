# todo

- 2025_01_31
  - [x] issue: request refactor
    - where: ``loc``
    - actual: name does not comply with approved verb list
    - solution: ``Get-LocationString``

- 2025_02_02
  - DemandScript
    - [ ] Register argument completer instead of writing the same one for each function

- Rename-Item
  - [ ] show loading feedback
  - [ ] consider returning something
- FileSystem
  - [ ] ``location.json``

    ```json
    {
        "Name": "PowerShell Profiles",
        "Tag": [
            "powershell", "pwsh", "profile", "Win10"
        ],
        "Where": "%UserProfile%/Documents/WindowsPowerShell"
    },
    {
        "Name": "PowerShell Profiles",
        "Tag": [
            "powershell", "pwsh", "profile", "Win11", "Version5"
        ],
        "Where": "%OneDrive%/Documents/WindowsPowerShell"
    },
    {
        "Name": "PowerShell Profiles",
        "Tag": [
            "powershell", "pwsh", "profile", "Win11", "Version7Core"
        ],
        "Where": "%OneDrive%/Documents/PowerShell"
    },
    ```

  - [ ] narrowing argument completer
  - [x] consider switching to ``-Mode And`` by default
  - [ ] consider Modes ``Union`` and ``Intersect``

---

[← Go Back](../readme.md)

