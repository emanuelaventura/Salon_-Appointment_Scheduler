#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=salon --no-align --tuples-only  -c"

#echo $($PSQL "TRUNCATE customers, appointments") 

echo -e "\n~~~~~ MY SALON ~~~~~\n"

echo -e "Welcome to My Salon, how can I help you?\n"

MAIN_MENU() {

  if [[ $1 ]]
  then
    echo -e "\n$1\n"
  fi
  
  $PSQL "SELECT service_id, name FROM services;" |
  while IFS='|' read SERVICE_ID SERVICE_NAME
  do
    SERVICE_ID=$(echo "$SERVICE_ID" | xargs)
    SERVICE_NAME=$(echo "$SERVICE_NAME" | xargs)

    echo "$SERVICE_ID) $SERVICE_NAME"
  done

  read SERVICE_ID_SELECTED
  SERVICE_EXISTS=$($PSQL "SELECT service_id FROM services WHERE service_id = $SERVICE_ID_SELECTED;")

  if [[ -z $SERVICE_EXISTS ]]
  then
      MAIN_MENU "I could not find that service. What would you like today?"
  else
    HANDLE_CUSTOMER
  fi

}

HANDLE_CUSTOMER() {
  # get name service
  SERVICE=$($PSQL "SELECT name FROM services WHERE service_id='$SERVICE_ID_SELECTED'")

  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  # get customer_id
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
  #echo "customer id found $CUSTOMER_ID"

  # if not found
  if [[ -z $CUSTOMER_ID ]]
  then
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME

    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(phone,name) VALUES('$CUSTOMER_PHONE' , '$CUSTOMER_NAME')")
    if [[ $INSERT_CUSTOMER_RESULT == "INSERT 0 1" ]]
    then
      #echo "Inserted into customers, $CUSTOMER_NAME"
      # get new customer_id
      CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
    fi
  else
    # get customer_name
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")
  fi

  echo -e "\nWhat time would you like your $SERVICE, $CUSTOMER_NAME?"
  read SERVICE_TIME

  INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id,service_id,time) VALUES($CUSTOMER_ID,$SERVICE_ID_SELECTED,'$SERVICE_TIME')")
  if [[ $INSERT_APPOINTMENT_RESULT == "INSERT 0 1" ]]
  then
    #echo "Inserted the appointment of $CUSTOMER_NAME"
    echo -e "\nI have put you down for a $SERVICE at $SERVICE_TIME, $CUSTOMER_NAME."
  fi
}

MAIN_MENU
