start_dir=`pwd`
#Setup PATH to include  mongo binaries if not yet done
#export PATH=$PATH:`pwd`/mongo_bin/bin

#Set path have mongo store data folders
export MONGO_ROOT=/lab


#Build the main data folders
mkdir -p $MONGO_ROOT
cd $MONGO_ROOT
mkdir -p {r1-1,r1-2,r1-3,r2-1,r2-2,r2-3,c1,c2,c3,m1}/data

#Start the processes

#replSet1
for i in `seq 1  3`;do
	mongod --fork --logpath r1-${i}/mongo.log  --dbpath r1-${i} --port 1700${i} --replSet r1 --shardsvr --nohttpinterface 
done

#replSet2
for i in `seq 1  3`;do
	mongod --fork --logpath r2-${i}/mongo.log  --dbpath r2-${i} --port 1800${i} --replSet r2 --shardsvr --nohttpinterface
done

#config
for i in `seq 1  3`;do
	mongod --fork --logpath c${i}/mongo.log  --dbpath c${i} --port 1900${i} --configsvr
done


echo "Building  ReplSet1" 
mongo --port 17001 --quiet --eval "var replSet='r1'" "${start_dir}/config_replset.js"
sleep 5
echo "Building ReplSet2"
mongo --port 18001 --quiet --eval "var replSet='r2'" "${start_dir}/config_replset.js"
sleep 5

echo "Sleeping to be nice..."
sleep 20

#mongos
echo "Starting Mongos"
mongos --fork --logpath m1/mongos.log --configdb localhost:19001,localhost:19002,localhost:19003
sleep 5
echo "Adding Shards"
mongo --eval "printjson(sh.addShard('r1/localhost:17001'))" --quiet
mongo --eval "printjson(sh.addShard('r2/localhost:18001'))" --quiet


echo  "Service\t\tPortRange"
echo  "Mongos\t\t27017"
echo  "Config\t\t19001-19003"
echo  "Shard1\t\t17001-17003"
echo  "Shard2\t\t18001-18003"
