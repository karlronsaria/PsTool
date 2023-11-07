# wish

- ``Qualify-Object``
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

## complete

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
