/*
Silo Model Importer v0.1
by Jim Holmes (jim@32bitkid.com)

Import SILO geometry from Silo's Native Format (.sia) 
*/

utility rolloutSiloImporter "Silo Importer" width:162 height:93
(
fn ImportSIAMesh = (
	vert_array = #()
	edge_array = #()
	face_array = #()
	uvw_array = #()	
	
	mymesh = convertToPoly(Mesh lengthsegs:0 widthsegs:0) 
	
	in_name = getOpenFileName caption:"Import Silo Mesh" types:"SIA Mesh File (*.SIA)|*.SIA|"
 
	if in_name == undefined then return false 
	
	in_file = openFile in_name mode:"rt"

	if in_file == undefined then return false
	
	version = readLine in_file
	
	while (eof(in_file) == false) do (
		data = stringStream(readLine in_file)
		cmd = readDelimitedString data " "
				
		case cmd of (
			"-Mat": (
				print "Reading Material Data"
				while (cmd != "-endMat") do (
					data = stringStream(readLine in_file)
					cmd = (readDelimitedString data " ")
				)
			)
			
			"-Shape": (
				print "Reading Shape Data"
				while (cmd != "-endShape") do (
					data = stringStream(raw = readLine in_file)
					cmd = (readDelimitedString data " ")
					if cmd == "-vert" do (
						local y = -(readDelimitedString data " ") as float
						local z = (readDelimitedString data " ") as float
						local x = -(readDelimitedString data " ") as float
						append vert_array [x,y,z]
						mymesh.createVertex [x,y,z]
					)
					
					if cmd == "-edge" do (
						local v1 = (readDelimitedString data " ") as float
						local v2 = (readDelimitedString data " ") as float
						append edge_array [v1,v2]
					)
					
					if cmd =="-face" do (
						local f = (readDelimitedString data " ") as integer
						face_array = #()
						for i = 1 to f do (
							local vertex = (readDelimitedString data " ") as integer
							local edge = (readDelimitedString data " ") as integer 
							local u = (readDelimitedString data " ") as float
							local v = (readDelimitedString data " ") as float
							append face_array (vertex+2)
						)
						mymesh.createFace face_array
						
					)

					if cmd == "-subl" do (
						local i = (readDelimitedString data " ") as integer
						ms = MeshSmooth()
						ms.iterations = i
						addModifier mymesh ms
					)
				)
			)
			
		)
		
	)
	
	mymesh.deleteIsoVerts()
	
	
	close in_file	
)
	label lbl1 "SILO Model Importer v0.1" pos:[20,4] width:132 height:16
	label lbl2 "" pos:[8,18] width:160 height:16

	button btnImport "Import .SIA" pos:[8,35] width:143 height:29
	on btnImport pressed do
		ImportSIAMesh()
)
