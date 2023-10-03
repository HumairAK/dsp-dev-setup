#!/usr/bin/env sh
push_artifact() {
    workspace_dir=$(echo $(context.taskRun.name) | sed -e "s/$(context.pipeline.name)-//g")
    workspace_dest=/workspace/${workspace_dir}/artifacts/$(context.pipelineRun.name)/$(context.taskRun.name)
    artifact_name=$(basename $2)
    if [ -f "$workspace_dest/$artifact_name" ]; then
        echo sending to: ${workspace_dest}/${artifact_name}
        tar -cvzf $1.tgz -C ${workspace_dest} ${artifact_name}
        aws s3 --endpoint <S3_ENDOINT> cp $1.tgz s3://<S3_BUCKET>/artifacts/$PIPELINERUN/$PIPELINETASK/$1.tgz
    elif [ -f "$2" ]; then
        tar -cvzf $1.tgz -C $(dirname $2) ${artifact_name}
        aws s3 --endpoint <S3_ENDOINT> cp $1.tgz s3://<S3_BUCKET>/artifacts/$PIPELINERUN/$PIPELINETASK/$1.tgz
    else
        echo "$2 file does not exist. Skip artifact tracking for $1"
    fi
}
push_log() {
    cat /var/log/containers/$PODNAME*$NAMESPACE*step-main*.log > step-main.log
    push_artifact main-log step-main.log
}
strip_eof() {
    if [ -f "$2" ]; then
        awk 'NF' $2 | head -c -1 > $1_temp_save && cp $1_temp_save $2
    fi
}