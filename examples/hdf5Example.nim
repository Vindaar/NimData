import nimhdf5
import nimdata
import typetraits
import docopt
import strutils

when defined(linux):
  const commitHash = staticExec("git rev-parse --short HEAD")
else:
  const commitHash = ""
# get date using `CompileDate` magic
const currentDate = CompileDate & " at " & CompileTime

const docTmpl = """
Version: $# built on: $#
Simple example of using NimData with dataframes

Usage:
  hdf5Example <h5file> [options]


Options:
  -h --help           Show this help
  --version           Show version.

"""
const doc = docTmpl % [commitHash, currentDate]

const InGridSchema = [
  intCol("eventNumber"),
  floatCol("length"),
  floatCol("width"),
  floatCol("skewnessLongitudinal"),
  floatCol("skewnessTransverse"),
  floatCol("kurtosisLongitudinal"),
  floatCol("kurtosisTransverse"),
  floatCol("rotationAngle"),
  floatCol("eccentricity"),
  floatCol("fractionInTransverseRms"),
  floatCol("lengthDivRmsTrans"),
]

const FadcSchema = [
  uint16Col("argMinval"),
  floatCol("minvals"),
  floatCol("baseline"),
  intCol("eventNumber"),
  uint16Col("fallTime"),
  uint16Col("riseTime"),
  uint16Col("riseStart"),
  uint16Col("fallStop")
]


type outType = schemaType(InGridSchema)
type outFadc = schemaType(FadcSchema)


proc main =

  let args = docopt(doc)

  let h5file = $args["<h5file>"]


  var names: seq[string]
  var tmp: outType
  echo names
  let df = fromHDF5[outType](DF,
                             h5file,
                             "/reconstruction/run_124/chip_3")

  let dfIngrid = df.cache()

  dfIngrid.map(record => record.projectTo(eventNumber, length))
    .filter(record => (record.eventNumber >= 1000 and record.eventNumber <= 1200))
    .take(15)
    .show()

  dfIngrid.map(record => record.projectTo(eventNumber, length))
    .drop(15000)
    .take(5)
    .show()

  let dfFadc = fromHDF5[outFadc](DF,
                                 h5file,
                                 "/reconstruction/run_124/fadc").cache()



  dfInGrid.take(5).show()

  dfFadc.take(5).show()

  let joined = joinTheta(
    dfIngrid,
    dfFadc,
    (a, b) => a.eventNumber == b.eventNumber,
    (a, b) => mergeTuple(a, b, ["eventNumber"])
  )

  joined.take(5).show()

  joined.scatterColor(x = eccentricity, y = riseTime, z = length).show()

  # NOTE: watch out for the types of e.g. `fallTime`. It's a uint16, but comparisons via
  # e.g. `<` require the same type!
  # Maybe use map like in the bottom example to convert the type!
  joined.filter(x => (x.fallTime.int > 400 and x.fallTime.int < 700))
    # plot histogram of all lengths corresponding to the above fall times
    .histPlot(length)
    .title("Another title than the default!")
    .show()

  # let's extract two columns, name them again as `riseTime` and `fallTime`, but conert them
  # to floats!
  joined.map(x => (
      riseTime: x.riseTime.float,
      fallTime: x.fallTime.float
    ))
    .take(5)
    .show()


  dfFadc.take(5).show()


  dfFadc.map(x => (fallTime: x.fallTime.float))
    .histPlot(fallTime)
    .binRange(-0.5, 600.5)
    .binSize(1.0)
    .title("test title!")
    .show()

  dfFadc.map(x => (riseTime: x.riseTime.float))
    .histPlot(riseTime)
    .binRange(-0.5, 600.5)
    .binSize(1.0)
    .show()

  dfFadc.map(x => (
    fallTime: x.fallTime.float,
    riseTime: x.riseTime.float))
    .take(5)
    .show()






  #var h5f = H5File(h5file, "r")
  #h5f.visit_file()
  #let dfOpen = fromHDF5[outType](DF,
  #                               h5f,
  #                               h5file,
  #                               "/reconstruction/run_124/chip_3")
  #
  #dfOpen.map(record => record.projectTo(eventNumber, eccentricity))
  #  .drop(15000)
  #  .filter(record => record.eccentricity <= 1.4)
  #  .take(5)
  #  .show()

when isMainModule:
  main()
