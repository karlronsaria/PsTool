# wish

- [ ] ``has`` Filter
- ``FileSystem#Rename-Item``
  - [ ] were case-sensitive

## complete

- Demand
  - [x] ability to add tags programatically
  - [x] a cmdlet that imports on-demand scripts requested by a local json file
    - solution: ``res/demandscript.setting.json#LocalDemandFile``

### 2023_12_28

- ``Qualify-Object``
  - [x] consider renaming to "``Query-Object``"
  - [x] index would narrow the results of other queries

    - example

      ```powershell
      cat .\res\package.json |
          ConvertFrom-Json |
          Qualify-Object -Index 2, 9 -Property Name, Version
      ```

      ```powershell
      cat .\res\package.json |
          ConvertFrom-Json |
          Qualify-Object 2, 9 -Property Name, Version
      ```

      ```powershell
      cat .\res\package.json |
          ConvertFrom-Json |
          Qualify-Object 2, 9, Name, Version
      ```

      ```powershell
      cat .\res\package.json |
          ConvertFrom-Json |
          Qualify-Object 2, Name, 9, Version
      ```

      All of the above would get the name and version info of
      packages 3 and 10.

  - [x] index range
    - solution
      - example

        ```powershell
        dir \note\*.md -Recurse |
            Qualify-Object -Index (2 .. 10)
        ```

        ```powershell
        dir \note\*.md -Recurse |
            what (2 .. 10)
        ```

- [x] better edge detection
- [x] progress bar
- I wish for
  - [x] select sheets
    - based on
      - [x] index
      - [x] index range
      - [x] substring
      - [x] pattern

---
[← Go Back](../readme.md)

