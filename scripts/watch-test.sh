scripts/test.sh

while inotifywait -e close_write,modify,move,delete -r .
do
    scripts/test.sh
done
