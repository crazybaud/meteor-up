FROM nelioteam/meteord:base
#docker build -t nelioteam/meteord:base-update .
RUN sed -i -e 's/node main.js/export MONGO_URL=$(cat \/run\/secrets\/mongo_url) \&\& node main.js/g' $METEORD_DIR/run_app.sh