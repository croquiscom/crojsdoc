If your repository is in the GitHub, you can serve your documentation using
[GitHub Pages](https://pages.github.com/) easily.
This guide shows how to setup GitHub pages with CroJSDoc.

See also [Creating Project Pages manually - GitHub Help](https://help.github.com/articles/creating-project-pages-manually).

# Clone your repository to the doc directory
```bash
# In your project root
$ git clone https://github.com/user/repository.git doc
Cloning into 'doc'...
done.

# Add doc to the ignore list
$ echo doc >> .gitignore
```

# Create a gh-pages branch
```bash
$ cd doc

$ git checkout --orphan gh-pages
Switched to a new branch 'gh-pages'

$ git rm -rf .
rm '.gitignore'
...
```

# Generate documentation
```bash
$ cd ..

$ crojsdoc
Total x files processed
```

# Commit and push
```bash
$ cd doc

$ git add .

$ git commit -m 'Update documentation'

$ git push origin gh-pages
```

# More options
If you delete master branch, you can omit repository and refspec arguments of git push.

```bash
$ git branch -D master

$ git push
```
