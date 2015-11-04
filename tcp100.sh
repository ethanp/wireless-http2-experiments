for i in `seq 0 $(($1-1))`; do
    (echo "asdf asdf sDF" | nc -l $((12345+$i)))&
done
wait
