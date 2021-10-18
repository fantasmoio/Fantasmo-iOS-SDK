set -e

echo -e "\n"
echo "--------------------------------------"
echo "git checkout master"
echo "git pull"
echo "git merge develop --no-edit"
echo "git push origin master"
echo "git checkout develop"
echo "--------------------------------------"
echo -e "\n"

read -e -p "Execute? [Y/n] " YN
if [[ $YN == "y" || $YN == "Y" || $YN == "" ]]; then
  echo "merging and pushing..."
  git checkout master
  git pull
  git merge develop --no-edit
  git push origin master
  git checkout develop
else
  exit 0
fi
