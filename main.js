let WORLDS = 8;
let LEVELS = 4;

function main()
{
	let zip = new JSZip();

	for(world = 1; world <= WORLDS; ++world)
	{
		for(level = 1; level <= LEVELS; ++level)
		{
			let leveldata = fengari.load(
				'generateLevel(' + world + ',' + level + ')')();
			zip.file(world + '-' + level + '.txt', leveldata);
		}
	}

	zip.generateAsync({type:"blob"}).then(function (blob)
	{
		saveAs(blob, "CartridgeTilt.zip");
	}, function (err) {
		console.log("Something went wrong trying to save the file.");
	});
}
