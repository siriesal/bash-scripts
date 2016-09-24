#!/bin/bash
# riesal@gmail.com
# copy with progress bar

copy_progress_bar()
{
   strace -q -ewrite cp -- "${1}" "${2}" 2>&1 \
      | awk '{
        count += $NF
            if (count % 10 == 0) {
               persen = count / total_size * 100
               printf "%3d%% [", persen
               for (i=0;i<=persen;i++)
                  printf "="
               printf ">"
               for (i=persen;i<100;i++)
                  printf " "
               printf "]\r"
            }
         }
         END { print "" }' total_size=$(stat -c '%s' "${1}") count=0
}
