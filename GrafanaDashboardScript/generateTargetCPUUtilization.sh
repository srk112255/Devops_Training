
dashboardname=ec2-cpu-utilization-across-all-accounts
curl -H "Authorization: Bearer eyJrIjoicnJhdmNoYTZXVnRYT1hyUDJnSkdEdUpmMEpUZXhXYzEiLCJuIjoiR3JhZmFuYUNMSSIsImlkIjoxfQ==" http://192.168.0.105:3000/api/dashboards/db/$dashboardname > Grafana.json

cat instances | while read output;
do	
	alias=`echo $output | cut -d',' -f1`
	instanceId=`echo $output | cut -d',' -f2`
	region=`echo $output | cut -d',' -f3`
	ref=`cat Grafana.json | jq '(.dashboard.rows[0].panels[0].targets | reverse)[0].refId' | sed 's|\"||g'`
	referenceId=`python increment.py $ref`
	cat CPUUtil.json | jq ".alias = \"$alias\" | .refId = \"$referenceId\" | .dimensions.InstanceId = \"$instanceId\" | .region = \"$region\" " > jsonfile
	jq --argfile obj jsonfile '.dashboard.rows[0].panels[0].targets += [$obj]' Grafana.json > tempjson
	mv tempjson Grafana.json
done

rm jsonfile

curl -XPOST -H "Authorization: Bearer eyJrIjoicnJhdmNoYTZXVnRYT1hyUDJnSkdEdUpmMEpUZXhXYzEiLCJuIjoiR3JhZmFuYUNMSSIsImlkIjoxfQ==" -H "Content-Type: application/json" http://192.168.0.105:3000/api/dashboards/db -d @Grafana.json
