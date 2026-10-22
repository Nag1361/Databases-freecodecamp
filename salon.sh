#! /bin/bash

echo "~~~~~ MY SALON ~~~~~"
echo
echo "Welcome to My Salon, how can I help you?"
echo

show_services() {
  psql --username=freecodecamp --dbname=salon -t --no-align -c "SELECT service_id || ') ' || name FROM services ORDER BY service_id;"
}

show_services
read SERVICE_ID_SELECTED

while true; do
  if [[ $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]; then
    SERVICE_NAME=$(psql --username=freecodecamp --dbname=salon -t --no-align -c "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
  else
    SERVICE_NAME=
  fi
  if [[ -n $SERVICE_NAME ]]; then
    break
  fi

  echo
  echo "I could not find that service. What would you like today?"
  show_services
  read SERVICE_ID_SELECTED
done

echo
echo "What's your phone number?"
read CUSTOMER_PHONE

CUSTOMER_RECORD=$(psql --username=freecodecamp --dbname=salon -t --no-align -c "SELECT customer_id || '|' || name FROM customers WHERE phone = '$CUSTOMER_PHONE';")

if [[ -z $CUSTOMER_RECORD ]]; then
  echo
  echo "I don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME
  CUSTOMER_ID=$(psql --username=freecodecamp --dbname=salon -t --no-align --quiet -c "INSERT INTO customers (phone, name) VALUES ('$CUSTOMER_PHONE', '$CUSTOMER_NAME') RETURNING customer_id;")
else
  IFS='|' read -r CUSTOMER_ID CUSTOMER_NAME <<< "$CUSTOMER_RECORD"
fi

echo
echo "What time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
read SERVICE_TIME

psql --username=freecodecamp --dbname=salon -c "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME');" > /dev/null

echo
echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."