--Silo Model Tools v0.5
--by Jim Holmes (jim@32bitkid.com)
--
--Import SILO geometry from Silo's Native Format (.sia) 
--
--v0.1: Inital Version
--v0.2: Bug Fix for multuple objects
--v0.5: Import/Export

utility rolloutSiloImporter "Silo Importer" width:162 height:93
(
fn exportSIAMesh tmesh = (
	if(classOf(tmesh) != Editable_Poly) do
   	(
		messageBox("Object must be a Editable Poly.")
   		return ok
   	)

	local fileName = getSaveFileName caption:"Save .SIA File" types:"Silo Mesh (*.SIA)|*.sia|"
	
	if fileName == undefined then return false
	
	out_file = createfile fileName
	
	format "-version1.0\n" to:out_file

	format "-Mat \n" to:out_file
	if tmesh.material != undefined then (
		format "-dif % % % 1\n" (tmesh.material.diffuse.red/255) (tmesh.material.diffuse.green/255) (tmesh.material.diffuse.blue/255) to:out_file
		format "-amb % % % 1\n" (tmesh.material.selfillumination/100) (tmesh.material.selfillumination/100) (tmesh.material.selfillumination/100) to:out_file
		format "-spec 0 0 0 0\n" to:out_file
		format "-emis 0 0 0 0\n" to:out_file
		format "-shin %\n" (tmesh.material.specularLevel) to:out_file
		if (tmesh.material.diffuseMap != undefined) then format "-tex \"%\"\n" tmesh.material.diffuseMap.filename to:out_file
	) else (
		format "-dif 0.95 0.95 0.95 1\n" to:out_file
		format "-amb 0.95 0.95 0.95 1\n" to:out_file
		format "-spec 0 0 0 0\n" to:out_file
		format "-emis 0 0 0 0\n" to:out_file
		format "-shin 127\n" to:out_file
	)
	format "-name \"Max Material\"\n" to:out_file
	format "-endMat\n" to:out_file
	format "-Shape\n" to:out_file
	format "-shad 0\n" to:out_file
	format "-shadw 1\n" to:out_file

	for i = 1 to tmesh.numVerts do (
		temp = polyOp.getVert tmesh i
		format "-vert % % %\n" temp[1] temp[3] -temp[2]  to:out_file
	)
	for i = 1 to polyOp.getNumEdges tmesh do (
		temp = polyOp.getEdgeVerts tmesh i
		format "-edge % %\n" (temp[1]-1) (temp[2]-1) to:out_file
	)
	format "-setmat 0\n" to:out_file
	for i = 1 to polyOp.getNumFaces tmesh do (
		temp = polyOp.getFaceVerts tmesh i
		tempedges = polyOp.getFaceEdges tmesh i
		tmapverts = polyOp.getMapFace tmesh 1 i
		format "-face % " tempedges.count to:out_file
		for i = 1 to tempedges.count do (
			tuvw = polyOp.getMapVert tmesh 1 tmapverts[i]
			format "% % % % " (temp[i]-1) (tempedges[i]-1) tuvw[1] tuvw[2] to:out_file
		)
		format "\n" to:out_file
	)
	
	format "-axis % % % 1 0 0 0 1 0 0 0 1\n" tmesh.pivot.x tmesh.pivot.z -tmesh.pivot.y to:out_file
	format "-endShape\n" to:out_file
	
	close out_file
	
)

fn ImportSIAMesh = (
	mesh_array = #()
	material_array = #()

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
				newMat = standard()
				
				while (cmd != "-endMat") do (
					data = stringStream(readLine in_file)
					cmd = (readDelimitedString data " ")
					
					if cmd == "-dif" do (
						local r = ((readDelimitedString data " ") as float) * 255
						local g = ((readDelimitedString data " ") as float) * 255
						local b = ((readDelimitedString data " ") as float) * 255
						newMat.diffuse = [r,g,b]
					)
					
					if cmd == "-amb" do (
						--local l = (readDelimitedString data " ") as float
						--newMat.selfIllumination = l * 255
					)
					
					if cmd == "-tex" do (
						local f = (readDelimitedString data " ")
						newMat.diffuseMap = Bitmaptexture fileName:(substring f 2 (f.count - 2))
					)					
				)
				
				showTextureMap newMat on
				append material_array newMat
				
			)
			
			"-Shape": (
				format "Reading Shape % Data\n" (mesh_array.count + 1)
				
				/* Reset */
				mymesh = convertToPoly(Mesh lengthsegs:0 widthsegs:0) 				
				polyop.setNumMaps mymesh 1
				polyop.setMapSupport mymesh 1 true
				
				vert_array = #()
				edge_array = #()
				face_array = #()
				uvw_array = #()
				face_count = 0
				uvw_count = 0
				
				
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
						face_count = face_count + 1 
						
						local f = (readDelimitedString data " ") as integer
						
						face_array = #()
						uvw_array = #()
						
						for i = 1 to f do (
							local vertex = (readDelimitedString data " ") as integer
							local edge = (readDelimitedString data " ") as integer 
							local u = (readDelimitedString data " ") as float
							local v = (readDelimitedString data " ") as float
							uvw_count = uvw_count + 1
							polyop.SetNumMapVerts mymesh 1 uvw_count keep:true
							polyop.setMapVert mymesh 1 uvw_count [u,v,0]
							append uvw_array uvw_count
							append face_array (vertex+2)
						)
						
						mymesh.createFace face_array
						polyop.setMapFace mymesh 1 face_count uvw_array
						
					)

					if cmd == "-subl" do (
						local i = (readDelimitedString data " ") as integer
						ms = MeshSmooth()
						ms.useRenderIterations = true
						ms.renderIterations = i
						ms.Iterations = 0
						addModifier mymesh ms
					)
					
					if cmd == "-axis" do (
						local x = (readDelimitedString data " ") as integer
						local z = (readDelimitedString data " ") as integer
						local y = -(readDelimitedString data " ") as integer
						mymesh.pivot = [x,y,z]
					)
					
					if cmd == "-setmat" do (
						local i = (readDelimitedString data " ") as integer
						mymesh.material = material_array[i+1]
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
	label lbl1 "SILO Model Tools v0.5" pos:[24,13] width:132 height:16

	button btnImport "Import .SIA" pos:[8,35] width:143 height:29
	on btnImport pressed do ImportSIAMesh()
		
	pickbutton pickObject "Export .SIA" pos:[16,68] width:128 height:32 message:"Select an Object for Export" toolTip:"Export Object"
	on pickObject picked obj do exportSIAMesh obj
)
