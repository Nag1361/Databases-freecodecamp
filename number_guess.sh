#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -q -c"
SECRET_NUMBER=$((RANDOM % 1000 + 1))

echo "Enter your username:"
read USERNAME
ESCAPED_USERNAME=${USERNAME//\'/\'\'}
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$ESCAPED_USERNAME'")

if [[ -z $USER_ID ]]
then
	USER_ID=$($PSQL "INSERT INTO users(username) VALUES('$ESCAPED_USERNAME') RETURNING user_id")
	echo "Welcome, $USERNAME! It looks like this is your first time here."
else
	GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id=$USER_ID")
	BEST_GAME=$($PSQL "SELECT MIN(number_of_guesses) FROM games WHERE user_id=$USER_ID")
	echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

NUMBER_OF_GUESSES=0
echo "Guess the secret number between 1 and 1000:"
while true
do
	read GUESS
	NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))

	if [[ ! $GUESS =~ ^-?[0-9]+$ ]]
	then
		echo "That is not an integer, guess again:"
		continue
	fi

	if [[ $GUESS == -* ]]
	then
		echo "It's higher than that, guess again:"
		continue
	fi

	GUESS_NUMBER=${GUESS#${GUESS%%[!0]*}}
	GUESS_NUMBER=${GUESS_NUMBER:-0}

	if (( ${#GUESS_NUMBER} > 4 )) || { (( ${#GUESS_NUMBER} == 4 )) && [[ $GUESS_NUMBER > 1000 ]]; }
	then
		echo "It's lower than that, guess again:"
	elif (( 10#$GUESS_NUMBER == SECRET_NUMBER ))
	then
		$PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES)" >/dev/null
		echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
		break
	elif (( 10#$GUESS_NUMBER > SECRET_NUMBER ))
	then
		echo "It's lower than that, guess again:"
	else
		echo "It's higher than that, guess again:"
	fi
done