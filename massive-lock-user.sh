#!/bin/bash

users=( user1 user2 user3 user4 user5 etc )

clear

echo -e "This script will lock the unused users from this server"
echo -e "It may take a while..\n"

for i in "${users[@]}"
do
  passwd -l $i
  echo -e "\tUser $i has been LOCKED successfuly"
done

echo -e "\nLocking completed, there are ${#users[@]} users in total."
