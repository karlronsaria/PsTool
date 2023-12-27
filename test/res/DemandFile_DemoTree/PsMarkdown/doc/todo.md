# To-do

- [ ] Grep: Get-MarkdownLink: should exclude inline code snippets

## complete

- [x] add module for use with PowerShell Version 6+
  - link: SetClipboard7
    - url: https://github.com/Yevrag35/SetClipboard7/blob/master/CSharp/SetClipboard-Core/Cmdlets/GetClipboard.cs
    - retrieved: 2023_11_15
  - consider
    - using Windows Forms
      - ex

        ```powershell
        Add-Type -AssemblyReference System.Windows.Forms

        # ...

        [System.Windows.Forms.Clipboard]::GetImage().Save($path)
        ```

---
[← Go Back](../readme.md)
