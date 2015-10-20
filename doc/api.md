<!---
This is an auto-generated file and should not be edited directly.
-->

## AntennaFlags

```
immutable AntennaFlags
```

A container that holds a $N \times 2$ array of flags where $N$ is the number of antennas. Each row of the array gives the flags for the $x$ and $y$ polarizations respectively.

```
AntennaFlags(Nant::Int)
```

Create an empty set of antenna flags for `Nant` antennas.

## ChannelFlags

```
immutable ChannelFlags
```

A container that holds a length $N$ vector of flags where $N$ is the number of frequency channels.

## applyflags!

```
applyflags!(ms::MeasurementSet, flags::ChannelFlags)
```

Apply the channel flags to the measurement set.

The flags are written to the "FLAG" column of the measurement set.

```
applyflags!(ms::MeasurementSet, flags::AntennaFlags)
```

Apply the antenna flags to the measurement set.

The flags are written to the "FLAG" column of the measurement set.

```
applyflags!(cal::GainCalibration, flags::GainCalibrationFlags)
```

Apply the set of flags to the gain calibration.

## bright_narrow_rfi

```
bright_narrow_rfi(ms)
```

Find RFI that is narrowband and very bright. This is the kind of RFI that is likely to make a frequency channel completely useless.

## clearflags!

```
clearflags!(mslist::Vector{MeasurementSet})
```

Clear all of the flags in the list of measurement sets.

```
clearflags!(ms::MeasurementSet)
```

Clear all of the flags in the measurement set.

## low_power_antennas

```
low_power_antennas(ms::MeasurementSet)
```

Search for antennas that appear to have very low power.

