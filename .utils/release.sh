set -e

echo -e "\n"
echo "--------------------------------------"
echo "git checkout develop"
echo "git pull"
echo "git checkout master"
echo "git pull"
echo "git merge develop --no-edit"
echo "git push origin master"
echo "git checkout develop"
echo "git rebase master"
echo "git checkout master"
echo "git merge develop --ff-only"
echo "git checkout develop"
echo "--------------------------------------"
echo -e "\n"

read -e -p "Execute? [Y/n] " YN
if [[ $YN == "y" || $YN == "Y" || $YN == "" ]]; then
  echo "merging and pushing..."
  # Make sure develop and master are up to date
  git checkout develop
  git pull
  git checkout master
  git pull
  # Merge develop into master with default merge commit
  git merge develop --no-edit
  git push origin master
  # Rebase development onto master and fast-forward
  git checkout develop
  git rebase master
  git checkout master
  git merge develop --ff-only
  git checkout develop
else
  exit 0
fi
