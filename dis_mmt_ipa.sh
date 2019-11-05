#!/bin/bash
# 买买提打包工具
# Author：陈胜
# Mail:  sheng.chen01@bqjr.cn
# Date：2017.3.2
# Update: 2019.10.31
#echo \printf  格式化输出　https://www.cnblogs.com/f-ck-need-u/p/5915076.html

#脚本使用说明  mmt_ipa.sh -h  请将xcocebuild 工具升级xcode7以上才能支持新语法.
#2019.09.24 => 兼容xcode11打包。
#name,version
#recordAppLog "买买钱包2017.09" "v1.2.3"

#上传Appstore密钥
#_apiIssuer="0444a414-8270-4582-a257-93f69491c574"
#_apiKey="392H4S596Q"
G_apiPwd="pdjw-bdbx-axsf-rzmm"
G_apiMail="mmlg@tibethuirong.com"
#######################

#//
function showErrorNoti(){
  osascript -e 'display notification "脚本执行失败,请关注！" with title "😂😂😂😂"'
}
function put_error() {
}

function put_warning() {
}
function put_prompt() {
}

date_start=`date +%s`
######################

ShellPath=$(cd "$(dirname "$0")"; pwd)

#工作副本目录,  可更新路径
WorkPath="${ShellPath}/"

#编译模式  Debug & Release
Configuration="Release"

echo -e '\n----------------------------------------------------'
echo '   买买提iOS APP上线工具 v1.0 20191029 by 陈胜/Sherwin'
echo -e '----------------------------------------------------\n'


echo -e "\n==>(0x01)-->获取工程基本信息..."
echo '----------------------------------------------------'
# 读取项目的当前工程的配置信息
#获取app显示名称
projectBuildSettings=$(xcodebuild -showBuildSettings)
#echo ${projectBuildSettings}

#获取app名称
APP_DisplayName=$(echo "${projectBuildSettings}" | grep PRODUCT_MODULE_NAME | head -1 | awk -F "= " '{print $2}')

#获取编译版本
APP_BVersion=$(echo "${projectBuildSettings}" | grep CURRENT_PROJECT_VERSION | head -1 | awk -F "= " '{print $2}')

#获取APP的主版本号
APP_Version=$(echo "${projectBuildSettings}" | grep MARKETING_VERSION | head -1 | awk -F "= " '{print $2}')

APP_TARGETNAME=$(echo "${projectBuildSettings}" | grep TARGETNAME | head -1 | awk -F "= " '{print $2}')

# 设置编译项目的taget
BuildTargetName=$APP_TARGETNAME


echo "APP_TARGETNAME: ${APP_TARGETNAME}"
echo "APP_DisplayName: ${APP_DisplayName}"
echo "APP_BVersion: ${APP_BVersion}"
echo "APP_Version: ${APP_Version}"

echo "(0x01)  √   NICE WORK."
echo ""

# 拷贝项目代码到工作目录
cd "${ShellPath}"
TEMP_F="temp"

###工程配置文件路径
echo -e "\n==>(0x02)-->配置工程文件路径..."
echo '----------------------------------------------------'
#cd "${TEMP_F}"
#获取当前工程名称.
project_path="${ShellPath}"
project_name=$(ls | grep xcodeproj | awk -F.xcodeproj '{print $1}')

#创建保存打包结果的目录
CU_DATA=`date +%Y-%m-%d_%H_%M`
result_path="${project_path}/build_release_${CU_DATA}"
mkdir -p "${result_path}"

if [ ! -e "${project_name}.xcodeproj" ]; then
  showErrorNoti
  echo "--> ERROR-错误401：找不到需要编译的工程,SO? 编译APP中断."
  exit 401
fi

echo "project_name: ${project_name}"
echo "result_path:  ${result_path}"
echo "(0x02)  √   NICE WORK."
echo ""

# 编译打包

#🕹😍😍😍archive路径
archivePath="${result_path}/${BuildTargetName}.xcarchive"

#导出ipa文件夹路径
IPA_DIR_PATH="${result_path}/${APP_DisplayName}_v${APP_Version}"

#🕹😍😍😍导出ipa包路径
IPA_PATH="${IPA_DIR_PATH}/${APP_TARGETNAME}.ipa"

#设置导ipa包的描述文件plist
exportOptionsPlist="${ShellPath}/iOSArchivefile/AppStoreExportOptions.plist"


#clean project.
echo -e "\n==>(0x03)-->开始清理工程,请稍等..."
echo '----------------------------------------------------'
xcodebuild clean \
-workspace "${ShellPath}/${project_name}".xcworkspace  \
-scheme "${BuildTargetName}" \
-configuration "${Configuration}"
if [[ $? != 0 ]]; then
    showErrorNoti
  　echo "--> ERROR-错误401：清理工程失败,请检查工程,SO? 编译APP中断."
  　exit 401
fi

echo "(0x03)  √   NICE WORK."
echo ""


#编译工程
echo -e "\n==>(0x04)-->开始编译，耗时操作,请稍等..."
echo '----------------------------------------------------'
echo "${project_name}"

#🕹😍😍😍打包，制作xcarchive文件，用于后续bug查看.clean build
xcodebuild  archive -quiet \
-workspace "${ShellPath}/${project_name}".xcworkspace  \
-scheme "${BuildTargetName}" \
-configuration "${Configuration}"  \
-archivePath "${archivePath}"

#判断是否存档成功.
if [ -e ${archivePath} ]; then
    echo "(0x04)  √  NICE WORK. 工程编译完成."
    echo ""
else
  showErrorNoti
  echo "--> ERROR-错误501：编译工程失败,请认真检查工程配置."
  exit 500
fi


#🕹😍😍😍导出ipa包
echo -e "\n==>(0x05)-->🕹🕹🕹开始导出IPA包，耗时操作,请稍等..."
echo '----------------------------------------------------'
xcodebuild -exportArchive \
-archivePath "${archivePath}" \
-exportPath "${IPA_DIR_PATH}" \
-exportOptionsPlist "${exportOptionsPlist}"

#判断是否导出成功.
if [ -e ${IPA_DIR_PATH} ]; then
    osascript -e 'display notification "AppStrore生产打包成功！" with title "😍😍😍"'
    echo "(0x05)  √  NICE WORK. ipa包导出成功."
    #open "${IPA_DIR_PATH}"
    #open -a Transporter.app
else
    showErrorNoti
    echo "--> ERROR-错误501：导出IPA失败,请认真检查工程配置."
    exit 1
fi

#--#--#--#--#--#--#--#--#--#--
#🕹😍😍😍 上传appStore操作.



#--verbose
#🕹😍😍😍较验 app状态(机审)
echo -e "\n==>(0x06)-->🕹🕹🕹开始较验IPA包，联网耗时操作,请稍等..."
echo '----------------------------------------------------'
echo "IPA_PATH: ${IPA_PATH}"
echo "G_apiMail: ${G_apiMail}"
echo "G_apiPwd:  ${G_apiPwd}"
echo -e '----------------------------------------------------\n'

validateInfo=$(xcrun altool --validate-app -f "${IPA_PATH}" -u $G_apiMail -p $G_apiPwd --output-format xml )

#判断较验是否成功
requestCode=$(echo "${validateInfo}" | grep 'product-errors')
if [ -n "$requestCode" ]; then
    echo "==>(0x06) 较验失败,请详细检测apple反馈数据包."
    echo "$validateInfo"
    exit 401
fi

echo "(0x06)  √  NICE WORK. ipa包较验成功."


#🕹😍😍😍上传IPA
echo -e "\n==>(0x07)-->🕹🕹🕹开始上传IPA包，联网耗时操作,请稍等..."
echo '----------------------------------------------------'

validateInfo=$(xcrun altool --upload-app -f "${IPA_PATH}" -u $G_apiMail -p $G_apiPwd --output-format xml )

#判断较验是否成功
requestCode=$(echo "${validateInfo}" | grep 'product-errors')
echo "requestCode:$requestCode"
if [ -n "$requestCode" ]; then
    echo "==>(0x07) 上传ipa包失败,请详细检测apple反馈数据包."
    echo "$validateInfo"
    exit 401
fi

echo -e "\n\n\n  (0x07)  √  NICE WORK. ipa包上传成功了."
echo "$validateInfo"

exit 0
