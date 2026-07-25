# Contributing to Sib

Anyone can take part in Sib's development. Open a new issue, comment
on an existing one, or fix one.

An issue does not have to report something broken. A command whose
behavior is harder to follow than it should be, or that just acts
stupid, is worth an issue too. Or a command living in your `.bashrc`
that you find so useful you think others should have it...

## What to work on

The roadmap lives in the issue tracker:
<https://github.com/sib-project/sib/issues>. If something is not there,
open it.

## Sending patches

Dependencies are bash >= 3.2, git, jq, curl, awk and coreutils.

Pull requests at <https://github.com/sib-project/sib>, or `git
format-patch` mailed to <sib-project@dilluti0n.com>. Both are read.

Write commit messages yourself. If nothing comes to mind, that is
usually the commit telling you it was not worth making.

Add a line at the end of the commit message:

    Signed-off-by: Your Name <your@email>

`git commit --signoff` does it for you. By signing off you certify the
[Developer Certificate of Origin](https://developercertificate.org/).
