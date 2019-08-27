output=''
node('s1qvap952') {
    print "DEBUG: parameter ENV NAME = ${ENVIRONMENT_NAME}"
    print "DEBUG: Repository NAME = ${REPOSITORY}"
    print "DEBUG: parameter Deploy Details= ${DEPLOYMENT}"
    print "DEBUG: BaseLineID = ${BASE_LINE_ID}"
	print "DEBUG: BRANCH_NAME = ${BRANCH}"
	print "DEBUG: ACM USER_NAME = ${USER_NAME}"
	print "DEBUG: ACM Component ID = ${COMPONENT_ID}"
			
		stage ('Prerequisite checking') {
			if ("${REPOSITORY}" == '' || "${BRANCH}" == ''){
				println "Repository or Branch parameters should not be empty"
				return
			}
		
			if ("${DEPLOYMENT}" == 'true' && "${ENVIRONMENT_NAME}" == ''){
				println "If deployment is TRUE then you need to provide the ENVIRONMENT_NAME"
				return
			}
			if ("${USER_NAME}" == '' || "${PASSWORD}" == '' || "${COMPONENT_ID}" == ''){
				println "Please enter the username and password values"
				return
			}
		
		}
    
        stage ('Trigger the ACM Build from Jenkins') {
			sh '/opt/escm/acm/acm_install/perl/bin/perl /opt/escm/acm/acm_cli/bin/autocm.pl -a build -usr ${USER_NAME} -pw ${PASSWORD} -ct ${COMPONENT_ID} -branch ${BRANCH} -bt full | tee baseline.txt'
			sh 'baseline=`cat baseline.txt | grep ${COMPONENT_ID} | awk \'{print $8}\'` && echo \$baseline > baseln.txt'
		    output = readFile('baseln.txt').trim()
			sh 'rm -rf pipeline.txt'
		}
		
        stage ('Build From Branch') {
			if ("${BRANCH}" != 'master'){
				git branch: '${BRANCH}',  credentialsId: 'webdep', url: '${REPOSITORY}'
			}
		}
        
        stage ('Build From Branch') {
			if ("${BRANCH}" != 'master'){
				sh "echo 'Preparing the package to copy to the archieve server......'"
				sh "cd ../${env.JOB_NAME}/src/RCTRR && mvn clean package && cd ../../ && cd src/RCTRR/../../package && tar -cvf  ${COMPONENT_ID}.tar TRRWeb-Service.ear batch trrweb && gzip -f -9 ${COMPONENT_ID}.tar && scp -r ${COMPONENT_ID}.tar.gz webdep@r3pvap1074.1dc.com:/vol_escm_archive/archive/${output}/${COMPONENT_ID}.tar.gz && scp -r ${COMPONENT_ID}.tar.gz webdep@r1pvap1127.1dc.com:/vol_escm_archive/archive/${output}/${COMPONENT_ID}.tar.gz"
			}
		}
	
        stage ("Status of Deployment") {		//an arbitrary stage name
			if ("${DEPLOYMENT}" == 'true' && "${BASE_LINE_ID}" == '') {
                paramAValue = "${output}"
				paramBValue = "${ENVIRONMENT_NAME}"
				paramCValue = "${USER_NAME}"
				paramDValue = "${PASSWORD}"
				paramEValue = "${COMPONENT_ID}"
				build job: 'TEST_rapconn_rc_trr_app_Pipeline1_single_pipeline_Deployment', parameters: [[$class: 'StringParameterValue', name: 'BASELINE_ID', value: paramAValue], [$class: 'StringParameterValue', name: 'ENVIRONMENTS', value: paramBValue], [$class: 'StringParameterValue', name: 'USER_NAME', value: paramCValue], [$class: 'StringParameterValue', name: 'PASSWORD', value: paramDValue], [$class: 'StringParameterValue', name: 'COMPONENT_ID', value: paramEValue]]
			}
				if ("${DEPLOYMENT}" == 'true' && "${BASE_LINE_ID}" != '') {
                paramAValue = "${BASE_LINE_ID}"
				paramBValue = "${ENVIRONMENT_NAME}"
				paramCValue = "${USER_NAME}"
				paramDValue = "${PASSWORD}"
				paramEValue = "${COMPONENT_ID}"
				build job: 'TEST_rapconn_rc_trr_app_Pipeline1_single_pipeline_Deployment', parameters: [[$class: 'StringParameterValue', name: 'BASELINE_ID', value: paramAValue], [$class: 'StringParameterValue', name: 'ENVIRONMENTS', value: paramBValue], [$class: 'StringParameterValue', name: 'USER_NAME', value: paramCValue], [$class: 'StringParameterValue', name: 'PASSWORD', value: paramDValue], [$class: 'StringParameterValue', name: 'COMPONENT_ID', value: paramEValue]]
            }
				if ("${DEPLOYMENT}" == 'false') {
                println "Deployment is false so stoped the Deployment"
                return
            }
        }
}
