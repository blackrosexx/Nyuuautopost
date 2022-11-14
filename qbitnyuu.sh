#!/bin/bash

##////////////////////////////////////////
#///             REQUIERD              ///
##////////////////////////////////////////

# Work directory:
DIR="/home/username/nzb"

# Nyuu path:
NYUU="/usr/bin/nyuu"
# ParPar path:
PARPAR="/usr/bin/parpar"

# Server url:
HOST="europe.myserver.com"
# Server port:
PORT="563"
# Server encryption:
SSL="true"
# Server username
USER="username"
# Server password:
PASS="password"
# Server max connections:
MAXCO="10"

#Your username on omgwtfnzbs
OMGUSERNAME="username"
#Your omgwtfnzbs api key
OMGAPI="apikey"
#Your Ninja Central api key
NINJAAPI="apikey"

##////////////////////////////////////////
#///             OPTIONAL              ///
##////////////////////////////////////////

# Temporary directory
TMP="$DIR/Temp"
# Output directory
CPL="$DIR/Completed"


# Use encryption?
ENC="true"
# Random encryption password?
ENCR="true"
# If false, custom password:
KEY="PlaceYourEncryptionKeyHere"

# Obfuscate nzb filename?
OBFS="false"
# Create log file? (include password)
LOG="true"

# Split archives?
SPLIT="true"
# Max archive size:
SIZE="250m"

# Use parchive?
USEPAR="true"
# Parchive redundancy:
REDUN="5%"

# Article size:
ASIZE="700K"
# Article poster:
POSTER="someonenice <someonenice@local>"
# Article group:
GROUP="alt.binaries.boneless"

# Debug mode (Upload, Posting and cleanup disabled)
DEBUG="false"

#//DO//NOT//EDIT//BELOW//THIS//LINE//
#/////////////////////////////////////////

set -m

FILE="%F"
TNAME="%N"

echo "--- Checking ---"

mkdir -p $TMP
mkdir -p $CPL

$NYUU --help &> /dev/null
if [ "$?" != 0 ] ; then
    echo "Error : check your Nyuu installation."
    exit 1 ; fi

$PARPAR --help &> /dev/null
if [ "$?" != 0 ] ; then
    echo "Error : check your ParPar installation."
    exit 1 ; fi


echo "--- Step 1 - Preparing ---"

HASH=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
DATE=`date '+%Y.%m.%d | %H:%M:%S'`

if [ $ENCR = "true" ] ; then
  KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1) ; fi

if [ $OBFS = "true" ] ; then
  NAME="$HASH" ; else
  NAME="$TNAME" ; fi

if [ $LOG = "true" ] ; then
  echo -------------------------------------------------------- >> $DIR/qbitnyuu.log
  echo Date : $DATE >> $DIR/qbitnyuu.log
  echo Original "Filename" : $TNAME  >> $DIR/qbitnyuu.log
  echo Archive "Filename" : $HASH >> $DIR/qbitnyuu.log
  echo Password : $KEY >> $DIR/qbitnyuu.log ; fi

echo "--- Step 2 - Packing ---"

ZARG="-mx0 -mhe=on"

if [ $ENC = "true" ] ; then
  ZARG="$ZARG -p$KEY" ; fi

if [ $SPLIT = "true" ] ; then
  ZARG="$ZARG -v$SIZE" ; fi

7z a $ZARG "$TMP/$HASH/$HASH.7z" "$FILE"

echo "--- Step 3 - Parchiving ---"

PARG="-s 700k -r $REDUN"

if [ $SPLIT = "true" ] ; then
  PARG="$PARG -p $SIZE" ; fi

if [ $USEPAR = "true" ] ; then
  $PARPAR $PARG -o "$TMP/$HASH/$HASH.par2" "$TMP/$HASH/"*7z* ; else
  echo "(SKIPPED)" ; fi

echo "--- Step 4 - Uploading ---"

if [ $SSL = "true" ] ; then
  SSLF="-S" ; else
  SSLF="" ; fi

if [ $DEBUG = "false" ] ; then
  $NYUU --nzb-password "$KEY" -h "$HOST" -P "$PORT" "$SSLF" -u "$USER" -p "$PASS" -n "$MAXCO" -a "$ASIZE" -f "$POSTER" -g "$GROUP" -o "$CPL/$NAME.nzb" $TMP/$HASH/* ; else
  echo "(SKIPPED)" ; fi

echo "--- Step 5 - Posting ---"

if [ $DEBUG = "false" ] ; then
  curl -X POST -k -s -L -m 60 -F "nzb="@$CPL/$NAME.nzb"" -F "catid=video" -F "upload=upload" "https://omgwtfnzbs.me/api-upload?user=$OMGUSERNAME&api=$OMGAPI"
  curl -X POST -F "file="@$CPL/$NAME.nzb"" -F "api=$NINJAAPI" https://ninjacentral.co.za/post-api ; else
  echo "(SKIPPED)" ; fi


echo "--- Step 6 - Cleaning Up ---"

if [ $DEBUG = "false" ] ; then
  rm -r $TMP/$HASH ; else
  echo "(SKIPPED)" ; fi

echo "--- Done ---"
