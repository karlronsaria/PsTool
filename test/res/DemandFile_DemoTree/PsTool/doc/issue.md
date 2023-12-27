# issue

## complete

- [x] 2023_12_25_033119
  - where: Demand#Install-DemandModule
  - howto: use ``InputObject`` argument completer in PowerShell 5 terminal
  - actual
    - fails

- [x] 2023_12_20_223459
  - where: Demand#Install-DemandModule
  - actual
    - every instance of ``$PsScriptRoot`` evaluates to ``C:\``
  - expacted
    - every instance of ``$PsScriptRoot`` evaluates to module script location

- [x] 2023_11_21_232252
  - where: ``Out-#Out-NotepadPlusPlus``
  - howto

    ```powershell
    dir \note | Out-NotepadPlusPlus
    ```

  - actual

    ```text
        Directory: C:\note

    Mode                 LastWriteTime         Length Name
    ----                 -------------         ------ ----
    d-----         5/24/2021   4:30 AM                banter

        Directory: C:\note

    Mode                 LastWriteTime         Length Name
    ----                 -------------         ------ ----
    d-----         5/18/2021   8:08 PM                dev

        Directory: C:\note

    Mode                 LastWriteTime         Length Name
    ----                 -------------         ------ ----
    d-----         5/25/2021  12:54 AM                howto
    ```

  - expected

    ```
        Directory: C:\note


    Mode                 LastWriteTime         Length Name
    ----                 -------------         ------ ----
    d-----         5/24/2021   4:30 AM                banter
    d-----         5/18/2021   8:08 PM                dev
    d-----         5/25/2021  12:54 AM                howto
    ```

- [x] 2022_03_23_230129
  - solution: DEPRECATE
  - where: ``Out-#Out-Notepad``
  - howto

    ```powershell
    'what' | Out-Notepad
    ```

  - system: Win11
  - actual: opens notepad.exe but does not change its window content

![2022_03_23_230129](./res/2022_03_23_230129.png)

- [x] 2022_03_23_225512
  - where: ``Pychart#Show-Pychart``
  - howto

    ```powershell
    Get-FolderSize | Show-Pychart
    ```

  - system: Win11
  - actual: shows blank

![2022_03_23_225512](./res/2022_03_23_225512.png)

---
[← Go Back](../readme.md)
