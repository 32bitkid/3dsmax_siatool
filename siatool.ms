/*
Silo Model Importer v0.2
by Jim Holmes (jim@32bitkid.com)

Import SILO geometry from Silo's Native Format (.sia) 

v0.1: Inital Version
v0.2: Bug Fix for multuple objects
*/

utility rolloutSiloImporter "Silo Importer" width:162 height:93
(
fn ImportSIAMesh = (
	mesh_array = #()

	in_name = getOpenFileName caption:"Import Silo Mesh" types:"SIA Mesh File (*.SIA)|*.SIA|"
 
	if in_name == undefined then return false 
	
	in_file = openFile in_name mode:"rt"

	if in_file == undefined then return false
	
	version = readLine in_file
	
	disableSceneRedraw() 
	
	Undo off ( 
	
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
				format "Reading Shape % Data\n" (mesh_array.count + 1)
				
				/* Reset */
				mymesh = convertToPoly(Mesh lengthsegs:0 widthsegs:0) 				
				
				vert_array = #()
				edge_array = #()
				face_array = #()
				uvw_array = #()	
				
				while (cmd != "-endShape") do (
					data = stringStream(raw = readLine in_file)
					cmd = (readDelimitedString data " ")
					if cmd == "-vert" do (
						local x = (readDelimitedString data " ") as float
						local z = (readDelimitedString data " ") as float
						local y = -(readDelimitedString data " ") as float
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
				/* Clean up */
				mymesh.deleteIsoVerts()
				append mesh_array mymesh
			)
			
			"-Inst": (
				/* Instance */
				while (cmd != "-endInst") do (
					data = stringStream(raw = readLine in_file)
					cmd = (readDelimitedString data " ")
					
					if cmd == "-snum" do (
						/* mymesh = instance mesh_array[((data as integer)+1)] */
					)
				)				
				
			)
			
		)
		
	)
	
	)

	/* Close File */
	close in_file
	
	enableSceneRedraw()
	
)
	label lbl1 "SILO Model Importer v0.2" pos:[20,13] width:132 height:16

	button btnImport "Import .SIA" pos:[8,35] width:143 height:29
	on btnImport pressed do
		ImportSIAMesh()
)
