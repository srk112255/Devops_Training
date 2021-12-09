
if [ $# -le 0 ]; then
	    echo "No arguments provided"
	    exit 1
fi
datasource=$1
dashboardname=ec2-cpu-utilization-across-all-accounts
curl -H "Authorization: Bearer eyJrIjoicnJhdmNoYTZXVnRYT1hyUDJnSkdEdUpmMEpUZXhXYzEiLCJuIjoiR3JhZmFuYUNMSSIsImlkIjoxfQ==" http://192.168.0.105:3000/api/dashboards/db/$dashboardname > Grafana.json

maxid=`cat Grafana.json | jq '(.dashboard.rows | reverse)[0].panels[0].id'`
cat Grafana.json | jq '.dashboard.rows[0]' > EC2UtilRow.json

cat EC2UtilRow.json | jq '.panels[0].targets =[]' > jsonfile
mv jsonfile EC2UtilRow.json

flag=false
cat instances | while read output;
do	
	alias=`echo $output | cut -d',' -f1`
	instanceId=`echo $output | cut -d',' -f2`
	region=`echo $output | cut -d',' -f3`
	if [ "$flag" = "false" ];then
		referenceId="A"
		flag=true
	else
		ref=`cat EC2UtilRow.json | jq '(.panels[0].targets | reverse)[0].refId' | sed 's|\"||g'`
		referenceId=`python increment.py $ref`
	fi
	cat CPUUtil.json | jq ".alias = \"$alias\" | .refId = \"$referenceId\" | .dimensions.InstanceId = \"$instanceId\" | .region = \"$region\" " > jsonfile
	jq --argfile obj jsonfile '.panels[0].targets += [$obj]' EC2UtilRow.json > tempjson
	mv tempjson EC2UtilRow.json
done

title="EC2 CPU Utilization for $datasource"
cat EC2UtilRow.json | jq ".panels[0].datasource = \"$datasource\" | .panels[0].title = \"$title\" " > jsonfile
mv jsonfile EC2UtilRow.json

newid=`expr $maxid + 1`
cat EC2UtilRow.json | jq ".panels[0].id = $newid " > jsonfile
mv jsonfile EC2UtilRow.json

title="EC2 CPU Utilization for $datasource alert"
cat EC2UtilRow.json | jq ".panels[0].alert.name = \"$title\" " > jsonfile
mv jsonfile EC2UtilRow.json


jq --argfile obj EC2UtilRow.json '.dashboard.rows += [$obj]' Grafana.json > tempjson
mv tempjson Grafana.json

curl -XPOST -H "Authorization: Bearer eyJrIjoicnJhdmNoYTZXVnRYT1hyUDJnSkdEdUpmMEpUZXhXYzEiLCJuIjoiR3JhZmFuYUNMSSIsImlkIjoxfQ==" -H "Content-Type: application/json" http://192.168.0.105:3000/api/dashboards/db -d @Grafana.json
