# Sib: a standard Unix LLM client

I like Git a bit too much, so Sib stores LLM conversations using Git
itself instead of SQLite. Your store is a plain Git repository, and
each user and assistant turn is a commit.

This gives you:
  - **Full control of the context.** Just like git does.
  - **Backup and sharing for free.** The store is a normal Git
    repository, so any Git host works as a remote.

---

- [Description](#description) - introducing concept with tutorial
- [Quickstart](#quickstart) - installation and setups
- [Tips](#tips) - usage examples
- [Hacking](#hacking) - extending Sib as you please

## Description

Typical usage:

    echo 'Why did Evangelion 3.0 suddenly go off the rails?' | sib ask
    sib log
    echo 'Which of those two reasons matters more?' | sib ask

`sib ask` reads a prompt from stdin, sends it to the model along with
every turn reachable from `HEAD`, prints the reply to stdout, and
records both turns as two commits. `sib log` prints the whole
conversation.

Now, the store looks like this:

    * fa754c HEAD~3 {"role":"user", "content":"Why did Evangelion 3.0 suddenly ..."}
    * b16df7 HEAD~2 {"role":"assistant", "content":"Because *Evangelion 3.0: You ..."}
    * 1c2e90 HEAD~1 {"role":"user", "content":"Which of those two reasons matters ..."}
    * 280f09 HEAD   {"role":"assistant", "content":"The **intentional creative ..."}

This is the overall concept. But why? It looks unnecessarily
complicated.

---

Let's look at a command like this:

    sib ask -rp HEAD~1

What each flag does:
  - `-r`: do not read stdin; send the chain to endpoint as is
  - `-p HEAD~1`: treat `HEAD~1` as the parent instead of `HEAD`

Since your last prompt lives at `HEAD~1`, this is the same as the
'Repeat' button seen in the web UI.

Without `-r`:

    echo 'So you mean the 14-year skip was a good decision?' | sib ask -p HEAD~2

This is similar to the 'Edit' button. It forks from `HEAD~2`, as if
you edited `1c2e90` in a web UI.

    * fa754c HEAD~3 {"role":"user", "content":"Why did Evangelion 3.0 suddenly ..."}
    * b16df7 HEAD~2 {"role":"assistant", "content":"Because *Evangelion 3.0: You ..."}
    * 32e3f4 HEAD~1 {"role":"user", "content":"So you mean the 14-year skip was a ..."}
    * 8cc404 HEAD   {"role":"assistant", "content":"Artistically, yes; narratively, ..."}

Hashes are hard to remember, so name them:

    sib save eva-3.0-go-off
    sib save -l               # List saved names

The saved name can be addressed with `-p` (and other commands like
`sib log` ...):

    sib git fetch https://github.com/sib-project/hub \
        dilluti0n/why-evangelion-end-like-that:refs/conv/why-evangelion-end-like-that

    sib log why-evangelion-end-like-that

    echo 'learning to accept himself? Honestly speaking, did he really succeed?' \
        'Why is he being congratulated?' | sib ask -p why-evangelion-end-like-that

Each save stays in place by default and does not follow the `sib
ask`. If the result matches the original name and you like it, save it
one more time.

    sib save why-evangelion-end-like-that

Your Evangelion 3.0 chain is of course still there:

    sib log eva-3.0-go-off

You can pick it up again with `sib ask -p`. But sometimes you only
want to move HEAD:

    sib ask -crp eva-3.0-go-off

`-c` is new here: no API call, so no assistant turn. With `-r` there is
no input either, so all that is left is moving `HEAD`.

These cover nearly every use case for Sib.

Knowing how conversations are saved gives you Repeat, Edit, Fork,
saving conversations, and switching conversations. [Backup and
sharing](#tips) come from the same place. Other tools ship each of
them as a separate named feature. Sib does not have to.

That's why.

## Quickstart

Here lies the unavoidable boilerplate you must endure to use Sib.

Dependencies are bash >= 3.2, git, [jq](https://jqlang.org/), curl,
awk and coreutils.

Download [release
tarball](https://github.com/sib-project/sib/releases/latest) or clone
this repo:

    git clone https://github.com/sib-project/sib

Global install:

    sudo make install

User install:

    make PREFIX="$HOME/.local" install

    # on macOS, add this line to .zshrc and rerun terminal
    export PATH="$HOME/.local/bin:$PATH"

Init the repository:

    sib init

Check defaults:

    $ sib status
    SIB_DIR:      /home/hskim/.sib
    PLM_MODEL:    gpt-5.6-luna
    PLM_ENDPOINT: https://api.openai.com/v1/responses

    HEAD: (unborn)

Change the endpoint/model (defaults work out of the box for openai).

    sib config edit # Inspect and edit the defaults
    sib config set sib.endpoint https://api.cyberdyne.com/v1/responses
    sib config set sib.model skynet-101-arnold

Export the API key:

    export PLM_API_KEY='sk-xxxxxx' # Add this to ~/.bashrc to make it persist
    export OPENAI_API_KEY='sk-xxxxxx' # This also works

Ask something:

    echo 'Why did Evangelion end like that?' | sib ask
    sib ask -rp HEAD~1 -m skynet-500   # Re-ask with other model

Now, enjoy!

## Tips

### Sharing

We previously fetched the conversation in the tutorial:

    sib git fetch https://github.com/sib-project/hub \
        dilluti0n/nvim-sib-log-res:refs/conv/nvim-sib-log-res

The above command copies the conversation directly to your repository.
You can read it with `sib log nvim-sib-log-res` or continue it wherever
you want with `sib ask -p nvim-sib-log-res`.

The reverse works too:

    sib git push <your-repo-url> <local-ref>:refs/heads/<remote-ref>

Wanna share yours with random internet dudes? In fact, you can publish
to [sib-project/hub](https://github.com/sib-project/hub) too. Push to
any public git repo as above and [open a share
issue](https://github.com/sib-project/hub/issues/new?template=share.yml). It
will be automatically published.

### Usage of sib ask

`sib ask` has a lot of flags. That is because it does a lot of things
in the first place. Each flag changes one part of what it does, and
they combine.

For example:

    echo 'Summarize the entire context for use in the next conversation.' | sib ask
    sib show -c | sib ask -nc

`sib show -c` prints only `content` field of `HEAD`, which is the
summary just generated. `-n` ignores the existing `HEAD`, creates a
new chain and switch to it. `-c` chains only user turns without
querying the model.

So when a conversation gets too long, this starts a fresh one while
carrying the context over.

### Markdown rendering and emacs/neovim extension

If you need Markdown rendering:

    sib log | glow -p

Or inside neovim:
```sh
{ echo Write a code which do same thing in neovim lua; echo; cat <<EOF
(defun sib-log ()
  (interactive)
  (require 'markdown-mode)

  (let ((buf (get-buffer-create "*sib*"))
        (err (get-buffer-create "*sib-error*")))
    (async-shell-command "sib log" buf err)

    (with-current-buffer buf
      (markdown-mode)
      (font-lock-ensure))

    (pop-to-buffer buf)))
EOF
} | sib ask -n
```

To save you API usage, I've already done it for you. Set it up with
the following commands:

    sib git fetch https://github.com/sib-project/hub \
        dilluti0n/nvim-sib-log-res:refs/conv/nvim-sib-log

    sib show -c nvim-sib-log >> ~/.config/nvim/init.lua
    nvim +SibLog

Also, I checked it does the things, but I don't really know much about
Neovim or Lua. So the generated script came out at 74 lines (the elisp
above is 12) and may be hard to maintain.

The nice part is, you already have the whole conversation behind it!
So someone who actually knows their way around could pick it up from
any turn, refactor it with AI, and upload an improved version.

## Hacking

`sib <cmd>` execs `sib-<cmd>` from `PATH`. Every command you have used
so far is just that: a script sitting next to the dispatcher.

So is yours. The hub URL above is too long to type twice:

    #!/usr/bin/env bash
    # sib-hub, anywhere in $PATH
    exec sib git fetch https://github.com/sib-project/hub "$1:refs/conv/${1#*/}"

And run with

    sib hub dilluti0n/nvim-sib-log-res
    sib show nvim-sib-log-res

What makes this cheap is the plumbing underneath. A conversation is a
*chain* of commits. Each commit's tree is a *trace*, a flat key-value
map (`role`, `content`, `model`, ...) whose values are blobs.

    sib rev-jsonl <chain>         Print <chain> to jsonl format
    sib chain-jsonl               Chain jsonl file to sib store and print its id

    sib rev-parse / show-ref / update-ref / ls-refs / symbolic-ref
    sib git ...                   raw git on the store

There are other commands, but for now, the above is all you need to
know.

- A manual page is planned; if you want to write it first, see
  [contribute](CONTRIBUTING.md).
- The [sib-ask](./sib-ask) code (49 lines excluding flag parsing)
  will also help.

These resources are not fully documented yet, so some of it may not be
obvious. Please feel free to ask about it via
[email](mailto:sib-project@dilluti0n.com) or issue tracker at any
time.

### Minimum rules for compatibility

- Keys matching glob pattern `_SIBTRACE*` are reserved.
- Keys must match `[A-Za-z_][A-Za-z0-9._-]*`.
- The other keys don't matter except `content`.
- The commit date is fixed at `999999999 +0000`, with author and
  committer `Sibyl <sib@local>`. Through this, we can obtain the same
  hash for the same conversation chain.

The project is in its early stages. The codebase is not yet stable
enough for large feature work, but you can get involved in shaping
the core API.

---

Copyright 2026 Hee-Suk Kim.

This program is free software, released under the GNU General Public
License, version 3 only. See [COPYING](COPYING) or
<https://www.gnu.org/licenses/>.
