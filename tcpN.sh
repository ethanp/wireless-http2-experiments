if [ "$#" -ne 1 ]; then
    echo "usage: $(basename "$0") n"
    exit 1
fi

for i in `seq 0 $(($1-1))`; do
    (echo "asdf asdf sDF" | nc -l $((12345+$i)))&
done
wait
