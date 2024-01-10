# 功能：同步远程目录中所有文件到本地

# 设置本地目录和远程主机目录的路径
$localPath = "填写对应本地目录"
$remotePath = "填写远程主机目录"

# 硬编码用户名和密码?
$Username = "访问远程共享文件的用户名"
$Password = "访问远程共享文件的密码"

# 将密码转换为安全字符
$SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force

# 创建凭据对象
$remoteCredential = New-Object System.Management.Automation.PSCredential -ArgumentList $Username, $SecurePassword

# 映射远程共享到虚拟驱动器
New-PSDrive -Name P -PSProvider FileSystem -Root $remotePath -Credential $remoteCredential -Persist

# 获取本地目录和远程主机目录的文件列表
$localFiles = Get-ChildItem -Path $localPath -File -Recurse
$remoteFiles = Get-ChildItem -Path P: -File -Recurse

if($remoteFiles)
{
	# 对比远程主机和本地对应目录，并返回差异结果
    if($localFiles)
    {
        $filesToUpdate = Compare-Object $remoteFiles $localFiles -Property Name, LastWriteTime -PassThru
    }
    else
    {
        $filesToUpdate = $remoteFiles
    }

	# 遍历需要更新的文件并将其复制到本地
	foreach ($file in $filesToUpdate) {
		# 若文件在远程上存在而本地不存在则拷贝到本地
		if($file.SideIndicator -eq "<=")
        {
            $relativePath = $file.FullName.Substring(2)
            $localFilePath = Join-Path $localPath $relativePath
            $targetDirectory = Join-Path $localPath ($file.Directory.FullName.Substring(2))

			# 如何待拷贝文件所在目录在本地没有，则创建目录
            if (-not (Test-Path $targetDirectory)) {
                New-Item -ItemType Directory -Path $targetDirectory -Force
            }

		    Copy-Item -Path $file.FullName -Destination $localFilePath -Force -Recurse
		    Write-Host "Update Remote File $($file.Name) To Local"
        }
        elseif($file.SideIndicator -eq ">=")
        {
			# 如果本地有而远程主机上没有该文件
        }
        else
        {
			# 如果两个相同文件版本不同
        }
	}
} else {
	Write-Host "There is no file to update"
}

# 删除虚拟驱动器映
Remove-PSDrive -Name P

Write-Host "Finished!"
