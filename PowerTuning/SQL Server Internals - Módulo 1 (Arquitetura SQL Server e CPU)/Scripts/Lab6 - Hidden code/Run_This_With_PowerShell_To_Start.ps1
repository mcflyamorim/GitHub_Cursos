Clear-Host

# Creating form with gif file...

[void][reflection.assembly]::LoadWithPartialName("System.Windows.Forms")
[void][reflection.assembly]::loadwithpartialname("System.Drawing")

$file = (get-item "$PSScriptRoot\Pic.gif")
$img = [System.Drawing.Image]::Fromfile($file);

[System.Windows.Forms.Application]::EnableVisualStyles();
$form = new-object Windows.Forms.Form
$button1 = New-Object System.Windows.Forms.Button
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState

function CallPsScript 
{
	Start-Process "$PSScriptRoot\Lab7.exe" -Verb runAs
}

$button1_OnClick = ${function:CallPsScript}

$OnLoadForm_StateCorrection=
{
	$form.WindowState = $InitialFormWindowState
}

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 262
$System_Drawing_Size.Width = 284
$form.ClientSize = $System_Drawing_Size
$form.DataBindings.DefaultDataSourceUpdateMode = 0
$form.Name = "Form"
$form.Text = "Demo Fabiano Amorim"

$button1.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 85
$System_Drawing_Point.Y = 250
$button1.Location = $System_Drawing_Point
$button1.Name = "CallPS"
$button1.Text = "Start demo"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 75
$button1.Size = $System_Drawing_Size
$button1.TabIndex = 0
$button1.UseVisualStyleBackColor = $True
$button1.add_Click($button1_OnClick)

$form.Controls.Add($button1)

$form.Width = $img.Size.Width + 20;
$form.Height =  $img.Size.Height + 100;
$pictureBox = new-object Windows.Forms.PictureBox
$pictureBox.Width =  $img.Size.Width + 100;
$pictureBox.Height =  $img.Size.Height + 100;

$InitialFormWindowState = $form.WindowState
$form.add_Load($OnLoadForm_StateCorrection)

$pictureBox.Image = $img;
$form.controls.add($pictureBox)
$form.Add_Shown( { $form.Activate() } )
$form.StartPosition = "CenterScreen" 
$form.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))

[environment]::exit(0)