(** Analyze module.

    Micro-benchmark usually uses a {i linear-regression} to estimates the
    execution time of a code segments. For example, the following table might
    represent [{!Measurement_raw.t} array] collected by {!Benchmark.run}:

    {v
  +-----+------+
  | run | time |
  +-----+------+
  | 1   | 19   |
  | 2   | 25   |
  | 3   | 37   |
  | 4   | 47   |
  | 5   | 56   |
  +-----+------+
    v}

    Bechamel records 3000 samples and the number of iterations can grows
    geometrically (see {!Benchmark.run}). Then, Bechamel can use 2 algorithms:

    - Ordinary Least Square
    - RANdom SAmple Consensus

    The user can choose one of it. Currently, {!OLS} is the best to use. These
    algorithms will estimate the actual execution time of the code segment.
    Using {!OLS} with the above data would yield an estimated execution time of
    [9.6] nanoseconds with a goodness of fit ([r²]) of [0.992].

    More generally, Bechamel lets the user choose the {i predictors} and
    {i responder}. Indeed, the user can use others metrics (such as [perf]) and
    the API allows to analyze such metrics together. *)

module OLS : sig
  module Ci95 : sig
    type t = private { r: float; l: float }
    val pp : t Fmt.t
  end

  type t

  val ols :
       ?bootstrap:int
    -> ?r_square:bool
    -> responder:string
    -> predictors:string array
    -> Measurement_raw.t array
    -> t

  val pp : t Fmt.t
  val predictors : t -> string list
  val responder : t -> string
  val estimates : t -> float list option
  val r_square : t -> float option
  val ci95 : t -> Ci95.t list option
end

module RANSAC : sig
  type t

  val ransac :
       ?filter_outliers:bool
    -> predictor:string
    -> responder:string
    -> Measurement_raw.t array
    -> t

  val pp : t Fmt.t
  val responder : t -> string
  val predictor : t -> string
  val mean : t -> float
  val constant : t -> float
  val max : t -> float * float
  val min : t -> float * float
  val error : t -> float
end

type 'a t
(** Type of analysis. *)

val ols : r_square:bool -> bootstrap:int -> predictors:string array -> OLS.t t
(** [ols ~r_square ~bootstrap ~predictors] is an Ordinary Least Square analysis
    on [predictors]. It calculates [r²] if [r_square = true]. [bootstrap] defines
     how many times Bechamel tries to {i resample} measurements. *)

val ransac : filter_outliers:bool -> predictor:string -> RANSAC.t t

val one : 'a t -> Measure.witness -> Benchmark.t -> 'a
(** [one analysis measure { Benchmark.stat; lr; kde; }] estimates the actual
    given [measure] for one [predictor]. So,
    [one analysis time { Benchmark.stat; lr; kde; }]
     wants to estimate actual {i run}-[time] (or execution time) value,
     where [analysis] is initialized with [run] {i predictor}. *)

val all :
     'a t
  -> Measure.witness
  -> (string, Benchmark.t) Hashtbl.t
  -> (string, 'a) Hashtbl.t
(** [all analysis measure tbl] is an application of {!val:one} for all results
    from the given [tbl]. *)

val merge :
     'a t
  -> Measure.witness list
  -> (string, 'a) Hashtbl.t list
  -> (string, (string, 'a) Hashtbl.t) Hashtbl.t
(** [merge witnesses tbls] returns a dictionary where the key is the {i label}
    of a measure (from the given [witnesses]) and the value is the result of
    this specific measure. *)
