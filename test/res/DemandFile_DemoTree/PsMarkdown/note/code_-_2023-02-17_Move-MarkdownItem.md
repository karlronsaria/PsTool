```
def Move-MarkdownItem
  in: src
  in: dst
  in: notebook

  links ← Get-MarkdownLink(src)
  cat ← Get-Content(src)

  foreach link in links
    abslink ← ToAbsoluteLink(link, src)
    rellink ← ToRelativeLink(abslink, dst)
    cat[link.Line] ←
      cat[link.Line]
        .Replace(
          link.Start,
          link.Length,
          rellink,
        )

  Out-File(dst, cat)

  grep ← dir notebook where t ⇒
    t match (Split-Path(src, leaf=True))
      and Test-Path(Get-Link(t))

  foreach item in grep
    cat ← Get-Content(link.FilePath)
    link ← Get-MarkdownLink(item.FilePath, item.Line)

    abslink ← ToAbsoluteLink(link, src)
    rellink ← ToRelativeLink(abslink, dst)
    cat[link.Line] ←
      cat[link.Line]
        .Replace(
          link.Start,
          link.Length,
          rellink,
        )

    Out-File(cat, link.FilePath)
```
