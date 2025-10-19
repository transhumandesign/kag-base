# Contributing Guidelines

After reading this document, you should have a good understanding of how to contribute to KAG!

If you're still stuck, want clarification on something or just want to sanity-check with a human, please drop into the `#development` channel on [our discord](https://discord.gg/kag) and ask! Contributions to improve this document are also welcome.

Before we get started, thank you for your interest! Community contribution helps keep the game alive, we really appreciate it!

## Setup Process

This repository is a replacement for the `Base` folder in your KAG installation. We recommend if you're going to contribute, that you set up two separate installations - one for "play" and one for "dev".

If you use steam, keep that as your "play" installation, and download the standalone version from [the official site](https://kag2d.com). Steam won't like the repository sitting over its files, and you may lose changes during an update.

In your "dev" folder, remove the contents of the `Base` folder, and then clone your fork into there.

You should end up with the contents of this repository right inside the `Base` folder - if you end up with `Base/Base` try again.

When running your dev copy, you'll want to run it without the launcher, and without autoupdate. You can accomplish this by running the game with the `nolauncher` and `noautoupdate` command line flags.

On Windows, save this as `dev_mode.bat` in your KAG "dev" root folder and run it instead of `KAG.exe` to launch the game.

```
KAG.exe nolauncher noautoupdate
```

On Linux, save this as `dev_mode.sh` and ensure it is executable.

```
#!/bin/sh
./KAG nolauncher noautoupdate
```

Following an update, patch your "play" installation as normal, copy any changed non-base files from there across to your "dev" installation (usually just `KAG.exe` and `Juxta.dll`, but check the changelog), and pull the changes from kag-base to your local repo.

If there is interest, scripts to handle this setup process can probably be prepared :)

__NOTE:__ if you're a tester, it's recommended that you patch your non-base files from your test copy rather than the release version, as the repository is sometimes more up to date than release is.

## Pull Request Process

This process is common to many repositories, but there are a few KAG-specific tips included as well.

- __Think of something to do!__

	Coming up with good changes that would help the game can be tricky, but it's the first step towards any contribution.

	Once you have an idea, talking about it in discord is a good way to gauge interest.

	If it's a big change, it's recommended to run it past a developer first!

- __Work in a named branch__

	We suggest that you don't work in `master`, and try to avoid github's automatic `patch-n` branch naming, as it's no better than a random number identifier. Name your branch something related to your feature like `new-bison-sprites` (use `kebab-case`).

	Working in a named branch makes issuing a pull request much less confusing when you get up to that stage, and leads to a more informative paper trail afterwards.

- __Keep changes separate__

	If you're doing concurrent work on multiple new features, please ensure that you're working on separate features in separate branches, to keep the PRs small and manageable.

	We won't generally accept PRs that are a big grab-bag of changes, so to save you the work of separating the changes later it is best to keep them separate to begin with.

	You're welcome to merge all your feature branches into your own master branch for testing of course!

	We recommend that you _do_ merge any upstream changes from `kag-base/master` into your branch from time to time, especially if you're getting ready to submit! This helps ensure that merging your changes goes as smoothly as possible. Just be careful not to merge any of your own stray changes in at the same time.

- __Make and test your changes__

	Now that you've got everything set up, it's time to do the actual work! Modify scripts, images, or config files to your heart's content to implement whatever it is you have schemed up.

	Try to commit often! Don't worry too much about a messy history at first - you'll get the hang of it.

- __Submitting your pull request__

	Once your changes are ready for us to review for integration, it's time to actually submit the pull request! You can see a detailed overview from github [here](https://help.github.com/articles/about-pull-requests/). We've got a PR template to keep formatting consistent.

	Pick a good, descriptive name that lets us know what it is that your PR contributes. _Added Support for Logging Match Outcomes_ is a fine name! _Logging Changes_ is a bit less good.

	Also, try to include as detailed a description as you can manage; this makes reviewers' lives easier when checking if changes make sense, and provides a good jumping-off-point for a discussion where needed.

	Screenshots and gifs of your contribution are encouraged! :)

	If your github account name is not identical to your KAG username, or you'd like to use a different name, please let us know who we should credit for the contribution!

- __If your pull request requires changes__

	Try not to be discouraged! We will generally optimistically merge as many changes as we can, but sometimes changes just aren't ready for primetime, or aren't suitable for the community.

	We ask that you engage with us and the community about your changes in the PR discussion thread on github, or in `#development` on discord. We're sure to be able to work something out!

- __Once your pull request is merged__

	Celebrate! Your changes will be included with the next public release of the game for everyone to enjoy. We look forward to more contributions from you in the future!

## Commit Message Format

This is not strictly enforced, but for historical changelog preparation reasons the kag repository commit messages have an established, slightly unorthodox format. If you want your commits to "fit in" or are intending to contribute long-term, we _do_ recommend you follow this format.

The format is `[tag] change description`. Multiple changes per commit are allowed but discouraged - put separate change descriptions on separate lines.

Smaller commits are preferred to larger ones where practical.

For example, commit c0b947847ce23f63258e20417d56889dfa2d9553 has the message `[fixed] dead fish pickup priority was the same as corpses'`. It only modifies the fishy scripts, and only fixes that one bug.

The available tags and their meanings are:
```
[added]    - a new file or feature was added
[removed]  - an existing file or feature was deleted or removed
[modified] - an existing file or feature was changed
[fixed]    - a bug was fixed
[fixed?]   - a tentative fix for a tricky/hard to reproduce bug
[updated]  - a dependency was updated to a new version
[dev]      - minor/hidden commit (generally omitted in the build notes)
```

## Code Style

The codebase uses a slightly idiosyncratic code style.

The important style points to remain consistent with are:

- Braces go on a new line.
- Indent with tabs, align with spaces, tabs are equal to 4 spaces anywhere it matters.

Less important (and more strange)

- `void VoidFunctionIsUpperCamel()`, `CBlob@ nonVoidIsLowerCamel()` - this is an inherited practice from MM. It's _fairly_ consistent across the codebase, but there are a few places that break the "rule". It's a strange one in any case. Sorry about that.
- Use the shorthand type names that specify width (`s32`, `u32`, `s16`, `u16`, `s8`, `u8`) as this helps when thinking about networking/blob property overhead (could you use a smaller type?).

## Help, I don't know git!

That's ok! It's not a _great_ situation to be in for big changes, but if you just want to correct a typo or tweak a number or two, or provide some more translations, you can do everything from within the github site.

If you'd like help with git or github, get in touch in the `#development` channel on discord and there'll usually be someone to help you on a case-by-base basis.

## How can I help, I don't know how to code or draw or anything!

That's ok too! There are plenty of non-development contributions you can make, such as raising [issues](https://github.com/transhumandesign/kag-base/issues), discussing [existing pull requests](https://github.com/transhumandesign/kag-base/pulls), applying to help with [testing](https://forum.thd.vg/threads/accepting-new-testers.25141/) the game, or answering questions about the game in `#help` on discord. You can also just vote in the `#democracy` polls on discord to help make your priorities known.

## How does this work, legally?

You agree to give THD irrevokable commercial and distribution rights to any submitted contributions.

You retain rights to use your contribution for other purposes and projects as you see fit - but we need to be able to use it without restriction as part of King Arthur's Gold, which is a commercial product at the time of writing.

## I think my changes will require engine modifications...

Contact us directly and we'll talk it out.

We may be able to organise engine access if you have a good contribution history and C++ experience, or else implement what you need to some agreed specification.

## Is there a reward? Will I be paid?

Contribution is made on a volunteer/gratis basis. Your reward is that your changes make the game better for everyone, everywhere, and that you're fostering a culture of collaboration that will improve the sustainability of the game :)

## My question wasn't answered...

Ask in `#development` and someone should be able to help you out!

## Thanks for reading!
