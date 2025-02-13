export splitting_field, issubfield, isdefining_polynomial_nice,
       quadratic_field, islinearly_disjoint, rationals_as_number_field

################################################################################
#
#  Base field
#
################################################################################

base_field(K::AnticNumberField) = FlintQQ

################################################################################
#
#  Order type
#
################################################################################

order_type(::AnticNumberField) = NfAbsOrd{AnticNumberField, nf_elem}

order_type(::Type{AnticNumberField}) = NfAbsOrd{AnticNumberField, nf_elem}

################################################################################
#
#  Predicates
#
################################################################################

issimple(::Type{AnticNumberField}) = true

issimple(::AnticNumberField) = true

################################################################################
#
#  Field constructions
#
################################################################################

@doc Markdown.doc"""
    NumberField(S::Generic.ResRing{fmpq_poly}; cached::Bool = true, check::Bool = true) -> AnticNumberField, Map

 The number field $K$ isomorphic to the ring $S$ and the map from $K\to S$.
"""
function NumberField(S::Generic.ResRing{fmpq_poly}; cached::Bool = true, check::Bool = true)
  Qx = parent(modulus(S))
  K, a = NumberField(modulus(S), "_a", cached = cached, check = check)
  mp = MapFromFunc(y -> S(Qx(y)), x -> K(lift(x)), K, S)
  return K, mp
end

function NumberField(f::fmpq_poly; cached::Bool = true, check::Bool = true)
  return NumberField(f, "_a", cached = cached, check = check)
end

function NumberField(f::fmpz_poly, s::Symbol; cached::Bool = true, check::Bool = true)
  Qx = Globals.Qx
  return NumberField(Qx(f), String(s), cached = cached, check = check)
end

function NumberField(f::fmpz_poly, s::AbstractString; cached::Bool = true, check::Bool = true)
  Qx = Globals.Qx
  return NumberField(Qx(f), s, cached = cached, check = check)
end

function NumberField(f::fmpz_poly; cached::Bool = true, check::Bool = true)
  Qx = Globals.Qx
  return NumberField(Qx(f), cached = cached, check = check)
end

function radical_extension(n::Int, gen::Integer; cached::Bool = true, check::Bool = true)
  return radical_extension(n, fmpz(gen), cached = cached, check = check)
end

function radical_extension(n::Int, gen::fmpz; cached::Bool = true, check::Bool = true)
  x = gen(Globals.Qx)
  return number_field(x^n - gen, cached = cached, check = check)
end

@doc doc"""
    cyclotomic_field(n::Int) -> AnticNumberField, nf_elem

The cyclotomic field defined by the $n$-th cyclotomic polynomial.

# Examples

```jldoctest
julia> cyclotomic_field(10)
(Cyclotomic field of order 10, z_10)
```
"""
function cyclotomic_field(n::Int; cached::Bool = true)
  return CyclotomicField(n, "z_$n", cached = cached)
end

# TODO: Some sort of reference?
@doc doc"""
    wildanger_field(n::Int, B::fmpz) -> AnticNumberField, nf_elem

Returns the field with defining polynomial $x^n + \sum_{i=0}^{n-1} (-1)^{n-i}Bx^i$.
These fields tend to have non-trivial class groups.

# Examples

```jldoctest
julia> wildanger_field(3, ZZ(10), "a")
(Number field over Rational Field with defining polynomial x^3 - 10*x^2 + 10*x - 10, a)
```
"""
function wildanger_field(n::Int, B::fmpz, s::String = "_\$"; check::Bool = true, cached::Bool = true)
  x = gen(Globals.Qx)
  f = x^n
  for i=0:n-1
    f += (-1)^(n-i)*B*x^i
  end
  return NumberField(f, s, cached = cached, check = check)
end

function wildanger_field(n::Int, B::Integer, s::String = "_\$"; cached::Bool = true, check::Bool = true)
  return wildanger_field(n, fmpz(B), s, cached = cached, check = check)
end

@doc Markdown.doc"""
    quadratic_field(d::IntegerUnion) -> AnticNumberField, nf_elem

Returns the field with defining polynomial $x^2 - d$.

# Examples

```jldoctest
julia> quadratic_field(5)
(Real quadratic field defined by x^2 - 5, sqrt(5))
```
"""
function quadratic_field(d::IntegerUnion; cached::Bool = true, check::Bool = true)
end

function quadratic_field(d::fmpz; cached::Bool = true, check::Bool = true)
  x = gen(Globals.Qx)
  if nbits(d) > 100
    a = div(d, fmpz(10)^(ndigits(d, 10) - 4))
    b = mod(abs(d), 10^4)
    s = "sqrt($a..($(nbits(d)) bits)..$b)"
  else
    s = "sqrt($d)"
  end
  q, a = number_field(x^2-d, s, cached = cached, check = check)
  set_special(q, :show => show_quad)
  return q, a
end

function show_quad(io::IO, q::AnticNumberField)
  d = trailing_coefficient(q.pol)
  if d < 0
    print(io, "Real quadratic field defined by ", q.pol)
  else
    print(io, "Imaginary quadratic field defined by ", q.pol)
  end
end

function quadratic_field(d::Integer; cached::Bool = true, check::Bool = true)
  return quadratic_field(fmpz(d), cached = cached, check = check)
end

@doc doc"""
    rationals_as_number_field() -> AnticNumberField, nf_elem

Returns the rational numbers as the number field defined by $x - 1$.

# Examples

```jldoctest
julia> rationals_as_number_field()
(Number field over Rational Field with defining polynomial x - 1, 1)
```
"""
function rationals_as_number_field()
  x = gen(Globals.Qx)
  return number_field(x-1)
end

################################################################################
#
#  Predicates
#
################################################################################

@doc Markdown.doc"""
    isdefining_polynomial_nice(K::AnticNumberField)

Tests if the defining polynomial of $K$ is integral and monic.
"""
function isdefining_polynomial_nice(K::AnticNumberField)
  return Bool(K.flag & UInt(1))
end

function isdefining_polynomial_nice(K::NfAbsNS)
  pols = K.pol
  for i = 1:length(pols)
    d = denominator(pols[i])
    if !isone(d)
      return false
    end
    if !isone(leading_coefficient(pols[i]))
      return false
    end
  end
  return true
end

################################################################################
#
#  Class group
#
################################################################################

@doc Markdown.doc"""
    class_group(K::AnticNumberField) -> GrpAbFinGen, Map

Shortcut for `class_group(maximal_order(K))`: returns the class
group as an abelian group and a map from this group to the set
of ideals of the maximal order.
"""
function class_group(K::AnticNumberField)
  return class_group(maximal_order(K))
end

################################################################################
#
#  Class number
#
################################################################################

@doc Markdown.doc"""
    class_number(K::AnticNumberField) -> fmpz

Returns the class number of $K$.
"""
function class_number(K::AnticNumberField)
  return order(class_group(maximal_order(K))[1])
end

################################################################################
#
#  Relative class number
#
################################################################################

@doc Markdown.doc"""
    relative_class_number(K::AnticNumberField) -> fmpz

Returns the relative class number of $K$. The field must be a CM-field.
"""
function relative_class_number(K::AnticNumberField)
  if degree(K) == 2
    @req istotally_complex(K) "Field must be a CM-field"
    return class_number(K)
  end

  fl, c = iscm_field(K)
  @req fl "Field must be a CM-field"
  h = class_number(K)
  L, _ = fixed_field(K, c)
  hp = class_number(L)
  @assert mod(h, hp) == 0
  return divexact(h, hp)
end

################################################################################
#
#  Basis
#
################################################################################

function basis(K::AnticNumberField)
  n = degree(K)
  g = gen(K);
  d = Array{typeof(g)}(undef, n)
  b = K(1)
  for i = 1:n-1
    d[i] = b
    b *= g
  end
  d[n] = b
  return d
end

################################################################################
#
#  Torsion units and related functions
#
################################################################################

@doc Markdown.doc"""
    istorsion_unit(x::nf_elem, checkisunit::Bool = false) -> Bool

Returns whether $x$ is a torsion unit, that is, whether there exists $n$ such
that $x^n = 1$.

If `checkisunit` is `true`, it is first checked whether $x$ is a unit of the
maximal order of the number field $x$ is lying in.
"""
function istorsion_unit(x::nf_elem, checkisunit::Bool = false)
  if checkisunit
    _isunit(x) ? nothing : return false
  end

  K = parent(x)
  d = degree(K)
  c = conjugate_data_arb(K)
  r, s = signature(K)

  while true
    @vprint :UnitGroup 2 "Precision is now $(c.prec) \n"
    l = 0
    @vprint :UnitGroup 2 "Computing conjugates ... \n"
    cx = conjugates_arb(x, c.prec)
    A = ArbField(c.prec, cached = false)
    for i in 1:r
      k = abs(cx[i])
      if k > A(1)
        return false
      elseif isnonnegative(A(1) + A(1)//A(6) * log(A(d))//A(d^2) - k)
        l = l + 1
      end
    end
    for i in 1:s
      k = abs(cx[r + i])
      if k > A(1)
        return false
      elseif isnonnegative(A(1) + A(1)//A(6) * log(A(d))//A(d^2) - k)
        l = l + 1
      end
    end

    if l == r + s
      return true
    end
    refine(c)
  end
end

@doc Markdown.doc"""
    torsion_unit_order(x::nf_elem, n::Int)

Given a torsion unit $x$ together with a multiple $n$ of its order, compute
the order of $x$, that is, the smallest $k \in \mathbb Z_{\geq 1}$ such
that $x^`k` = 1$.

It is not checked whether $x$ is a torsion unit.
"""
function torsion_unit_order(x::nf_elem, n::Int)
  ord = 1
  fac = factor(n)
  for (p, v) in fac
    p1 = Int(p)
    s = x^divexact(n, p1^v)
    if isone(s)
      continue
    end
    cnt = 0
    while !isone(s) && cnt < v+1
      s = s^p1
      ord *= p1
      cnt += 1
    end
    if cnt > v+1
      error("The element is not a torsion unit")
    end
  end
  return ord
end

#################################################################################################
#
#  Normal Basis
#
#################################################################################################

function normal_basis(K::AnticNumberField)
  # First try basis elements of LLL basis
  # or rather not
  # n = degree(K)
  # Aut = automorphisms(K)

  # length(Aut) != n && error("The field is not normal over the rationals!")

  # A = zero_matrix(FlintQQ, n, n)
  # _B = basis(lll(maximal_order(K)))
  # for i in 1:n
  #   r = elem_in_nf(_B[i])
  #   for i = 1:n
  #     y = Aut[i](r)
  #     for j = 1:n
  #       A[i,j] = coeff(y, j - 1)
  #     end
  #   end
  #   if rank(A) == n
  #     return r
  #   end
  # end

  O = EquationOrder(K)
  Qx = parent(K.pol)
  d = discriminant(O)
  p = 1
  for q in PrimesSet(degree(K), -1)
    if divisible(d, q)
      continue
    end
    #Now, I check if p is totally split
    R = GF(q, cached = false)
    Rt, t = PolynomialRing(R, "t", cached = false)
    ft = Rt(K.pol)
    pt = powermod(t, q, ft)
    if degree(gcd(ft, pt-t)) == degree(ft)
      p = q
      break
    end
  end

  return _normal_basis_generator(K, p)
end

function _normal_basis_generator(K, p)
  Qx = parent(K.pol)

  #Now, I only need to lift an idempotent of O/pO
  R = GF(p, cached = false)
  Rx, x = PolynomialRing(R, "x", cached = false)
  f = Rx(K.pol)
  fac = factor(f)
  g = divexact(f, first(keys(fac.fac)))
  Zy, y = PolynomialRing(FlintZZ, "y", cached = false)
  g1 = lift(Zy, g)
  return K(g1)
end

################################################################################
#
#  Subfield check
#
################################################################################

function _issubfield(K::AnticNumberField, L::AnticNumberField)
  f = K.pol
  R = roots(f, L, max_roots = 1)
  if isempty(R)
    return false, L()
  else
    h = parent(L.pol)(R[1])
    return true, h(gen(L))
  end
end

function _issubfield_first_checks(K::AnticNumberField, L::AnticNumberField)
  f = K.pol
  g = L.pol
  if mod(degree(g), degree(f)) != 0
    return false
  end
  t = divexact(degree(g), degree(f))
  try
    OK = _get_maximal_order_of_nf(K)
    OL = _get_maximal_order_of_nf(L)
    if mod(discriminant(OL), discriminant(OK)^t) != 0
      return false
    end
  catch e
    if !isa(e, AccessorNotSetError)
      rethrow(e)
    end
  end
  # We could factorize the discriminant of f, but we only test small primes.
  cnt_threshold = 10*degree(K)
  p = 3
  cnt = 0
  while cnt < cnt_threshold
    F = GF(p, cached = false)
    Fx = PolynomialRing(F, "x", cached = false)[1]
    fp = Fx(f)
    gp = Fx(g)
    if !issquarefree(fp) || !issquarefree(gp)
      p = next_prime(p)
	    continue
    end
    cnt += 1
    fs = factor_shape(fp)
    gs = factor_shape(gp)
    if !divisible(lcm(collect(keys(gs))), lcm(collect(keys(fs))))
      return false
    end
    p = next_prime(p)
  end
  return true
end

function issubfield(K::AnticNumberField, L::AnticNumberField)
  fl = _issubfield_first_checks(K, L)
  if !fl
    return false, hom(K, L, zero(L), check = false)
  end
  b, prim_img = _issubfield(K, L)
  return b, hom(K, L, prim_img, check = false)
end

function _issubfield_normal(K::AnticNumberField, L::AnticNumberField)
  f = K.pol
  f1 = change_base_ring(L, f)
  r = roots(f1, max_roots = 1, isnormal = true)
  if length(r) > 0
    h = parent(L.pol)(r[1])
    return true, h(gen(L))
  else
    return false, L()
  end
end

@doc Markdown.doc"""
      issubfield_normal(K::AnticNumberField, L::AnticNumberField) -> Bool, NfToNfMor

Returns `true` and an injection from $K$ to $L$ if $K$ is a subfield of $L$.
Otherwise the function returns "false" and a morphism mapping everything to 0.

This function assumes that $K$ is normal.
"""
function issubfield_normal(K::AnticNumberField, L::AnticNumberField)
  fl = _issubfield_first_checks(K, L)
  if !fl
    return false, hom(K, L, zero(L), check = false)
  end
  b, prim_img = _issubfield_normal(K, L)
  return b, hom(K, L, prim_img, check = false)

end

################################################################################
#
#  Isomorphism
#
################################################################################

@doc Markdown.doc"""
    isisomorphic(K::AnticNumberField, L::AnticNumberField) -> Bool, NfToNfMor

Returns "true" and an isomorphism from $K$ to $L$ if $K$ and $L$ are isomorphic.
Otherwise the function returns "false" and a morphism mapping everything to 0.
"""
function isisomorphic(K::AnticNumberField, L::AnticNumberField)
  f = K.pol
  g = L.pol
  if degree(f) != degree(g)
    return false, hom(K, L, zero(L), check = false)
  end
  if fmpq[coeff(f, i) for i = 0:degree(f)] == fmpq[coeff(g, i) for i = 0:degree(g)]
    return true, hom(K, L, gen(L))
  end
  if signature(K) != signature(L)
    return false, hom(K, L, zero(L), check = false)
  end
  try
    OK = _get_maximal_order_of_nf(K)
    OL = _get_maximal_order_of_nf(L)
    if discriminant(OK) != discriminant(OL)
      return false, hom(K, L, zero(L), check = false)
    end
  catch e
    if !isa(e, AccessorNotSetError)
      rethrow(e)
    end
    t = discriminant(f)//discriminant(g)
    if !issquare(numerator(t)) || !issquare(denominator(t))
      return false, hom(K, L, zero(L), check = false)
    end
  end
  p = 10^5
  cnt = 0
  df = denominator(f)
  dg = denominator(g)
  while cnt < max(20, 2*degree(K))
    p = next_prime(p)
    if divisible(df, p) || divisible(dg, p)
      continue
    end
    F = GF(p, cached = false)
    Fx = PolynomialRing(F, "x", cached = false)[1]
    fp = Fx(f)
    if degree(fp) != degree(f) || !issquarefree(fp)
      continue
    end
    gp = Fx(g)
    if degree(gp) != degree(g) || !issquarefree(gp)
      continue
    end
    cnt += 1
    lf = factor_shape(fp)
    lg = factor_shape(gp)
    if lf != lg
      return false, hom(K, L, zero(L), check = false)
    end
  end
  b, prim_img = _issubfield(K, L)
  if !b
    return b, hom(K, L, zero(L), check = false)
  else
    return b, hom(K, L, prim_img, check = false)
  end
end

################################################################################
#
#  Compositum
#
################################################################################

@doc Markdown.doc"""
    compositum(K::AnticNumberField, L::AnticNumberField) -> AnticNumberField, Map, Map

Assuming $L$ is normal (which is not checked), compute the compositum $C$ of the
2 fields together with the embedding of $K \to C$ and $L \to C$.
"""
function compositum(K::AnticNumberField, L::AnticNumberField)
  lf = factor(K.pol, L)
  d = degree(first(lf.fac)[1])
  if any(x->degree(x) != d, keys(lf.fac))
    error("2nd field cannot be normal")
  end
  KK = NumberField(first(lf.fac)[1])[1]
  Ka, mKa = absolute_simple_field(KK)
  mK = hom(K, Ka, mKa\gen(KK))
  mL = hom(L, Ka, mKa\(KK(gen(L))))
  embed(mK)
  embed(mL)
  return Ka, mK, mL
end

################################################################################
#
#  Serialization
#
################################################################################

# This function can be improved by directly accessing the numerator
# of the fmpq_poly representing the nf_elem
@doc Markdown.doc"""
    write(io::IO, A::Vector{nf_elem}) -> Nothing

Writes the elements of `A` to `io`. The first line are the coefficients of
the defining polynomial of the ambient number field. The following lines
contain the coefficients of the elements of `A` with respect to the power
basis of the ambient number field.
"""
function write(io::IO, A::Vector{nf_elem})
  if length(A) == 0
    return
  else
    # print some useful(?) information
    print(io, "# File created by Hecke $VERSION_NUMBER, $(Base.Dates.now()), by function 'write'\n")
    K = parent(A[1])
    polring = parent(K.pol)

    # print the defining polynomial
    g = K.pol
    d = denominator(g)

    for j in 0:degree(g)
      print(io, coeff(g, j)*d)
      print(io, " ")
    end
    print(io, d)
    print(io, "\n")

    # print the elements
    for i in 1:length(A)

      f = polring(A[i])
      d = denominator(f)

      for j in 0:degree(K)-1
        print(io, coeff(f, j)*d)
        print(io, " ")
      end

      print(io, d)

      print(io, "\n")
    end
  end
end

@doc Markdown.doc"""
    write(file::String, A::Vector{nf_elem}, flag::ASCIString = "w") -> Nothing

Writes the elements of `A` to the file `file`. The first line are the coefficients of
the defining polynomial of the ambient number field. The following lines
contain the coefficients of the elements of `A` with respect to the power
basis of the ambient number field.

Unless otherwise specified by the parameter `flag`, the content of `file` will be
overwritten.
"""
function write(file::String, A::Vector{nf_elem}, flag::String = "w")
  f = open(file, flag)
  write(f, A)
  close(f)
end

# This function has a bad memory footprint
@doc Markdown.doc"""
    read(io::IO, K::AnticNumberField, ::Type{nf_elem}) -> Vector{nf_elem}

Given a file with content adhering the format of the `write` procedure,
this function returns the corresponding object of type `Vector{nf_elem}` such that
all elements have parent $K$.

**Example**

    julia> Qx, x = FlintQQ["x"]
    julia> K, a = NumberField(x^3 + 2, "a")
    julia> write("interesting_elements", [1, a, a^2])
    julia> A = read("interesting_elements", K, Hecke.nf_elem)
"""
function read(io::IO, K::AnticNumberField, ::Type{Hecke.nf_elem})
  Qx = parent(K.pol)

  A = Vector{nf_elem}()

  i = 1

  for ln in eachline(io)
    if ln[1] == '#'
      continue
    elseif i == 1
      # the first line read should contain the number field and will be ignored
      i = i + 1
    else
      coe = map(Hecke.fmpz, split(ln, " "))
      t = fmpz_poly(Array(slice(coe, 1:(length(coe) - 1))))
      t = Qx(t)
      t = divexact(t, coe[end])
      push!(A, K(t))
      i = i + 1
    end
  end

  return A
end

@doc Markdown.doc"""
    read(file::String, K::AnticNumberField, ::Type{nf_elem}) -> Vector{nf_elem}

Given a file with content adhering the format of the `write` procedure,
this function returns the corresponding object of type `Vector{nf_elem}` such that
all elements have parent $K$.

**Example**

    julia> Qx, x = FlintQQ["x"]
    julia> K, a = NumberField(x^3 + 2, "a")
    julia> write("interesting_elements", [1, a, a^2])
    julia> A = read("interesting_elements", K, Hecke.nf_elem)
"""
function read(file::String, K::AnticNumberField, ::Type{Hecke.nf_elem})
  f = open(file, "r")
  A = read(f, K, Hecke.nf_elem)
  close(f)
  return A
end

#TODO: get a more intelligent implementation!!!
@doc Markdown.doc"""
    splitting_field(f::fmpz_poly) -> AnticNumberField
    splitting_field(f::fmpq_poly) -> AnticNumberField

Computes the splitting field of $f$ as an absolute field.
"""
function splitting_field(f::fmpz_poly; do_roots::Bool = false)
  Qx = PolynomialRing(FlintQQ, parent(f).S, cached = false)[1]
  return splitting_field(Qx(f), do_roots = do_roots)
end

function splitting_field(f::fmpq_poly; do_roots::Bool = false)
  return splitting_field([f], do_roots = do_roots)
end

function splitting_field(fl::Vector{fmpz_poly}; coprime::Bool = false, do_roots::Bool = false)
  Qx = PolynomialRing(FlintQQ, parent(fl[1]).S, cached = false)[1]
  return splitting_field([Qx(x) for x = fl], coprime = coprime, do_roots = do_roots)
end

function splitting_field(fl::Vector{fmpq_poly}; coprime::Bool = false, do_roots::Bool = false)
  if !coprime
    fl = coprime_base(fl)
  end
  ffl = fmpq_poly[]
  for x = fl
    append!(ffl, collect(keys(factor(x).fac)))
  end
  fl = ffl
  r = []
  if do_roots
    r = [roots(x)[1] for x = fl if degree(x) == 1]
  end
  fl = fl[findall(x->degree(x) > 1, fl)]
  if length(fl) == 0
    if do_roots
      return FlintQQ, r
    else
      return FlintQQ
    end
  end
  K, a = number_field(fl[1])#, check = false, cached = false)

  @assert fl[1](a) == 0
  gl = [change_base_ring(K, fl[1])]
  gl[1] = divexact(gl[1], gen(parent(gl[1])) - a)
  for i=2:length(fl)
    push!(gl, change_base_ring(K, fl[i]))
  end

  if do_roots
    K, R = _splitting_field(gl, coprime = true, do_roots = Val{true})
    return K, vcat(r, [a], R)
  else
    return _splitting_field(gl, coprime = true, do_roots = Val{false})
  end
end


copy(f::fmpq_poly) = parent(f)(f)
gcd_into!(a::fmpq_poly, b::fmpq_poly, c::fmpq_poly) = gcd(b, c)

@doc Markdown.doc"""
    splitting_field(f::PolyElem{nf_elem}) -> AnticNumberField

Computes the splitting field of $f$ as an absolute field.
"""
splitting_field(f::PolyElem{nf_elem}; do_roots::Bool = false) = splitting_field([f], do_roots = do_roots)

function splitting_field(fl::Vector{<:PolyElem{nf_elem}}; do_roots::Bool = false, coprime::Bool = false)
  if !coprime
    fl = coprime_base(fl)
  end
  ffl = eltype(fl)[]
  for x = fl
    append!(ffl, collect(keys(factor(x).fac)))
  end
  fl = ffl
  r = []
  if do_roots
    r = [roots(x)[1] for x = fl if degree(x) == 1]
  end
  lg = [k for k = fl if degree(k) > 1]
  if length(lg) == 0
    if do_roots
      return base_ring(fl[1]), r
    else
      return base_ring(fl[1])
    end
  end

  K, a = number_field(lg[1])#, check = false)
  ggl = [map_coefficients(K, lg[1])]
  ggl[1] = divexact(ggl[1], gen(parent(ggl[1])) - a)

  for i = 2:length(lg)
    push!(ggl, map_coefficients(K, lg[i]))
  end
  if do_roots == Val{true}
    R = [K(x) for x = r]
    push!(R, a)
    Kst, t = PolynomialRing(Ks, cached = false)
    return _splitting_field(vcat(ggl, [t-y for y in R]), coprime = true, do_roots = Val{true})
  else
    return _splitting_field(ggl, coprime = true, do_roots = Val{false})
  end
end


function _splitting_field(fl::Vector{<:PolyElem{<:NumFieldElem}}; do_roots::Type{Val{T}} = Val{false}, coprime::Bool = false) where T
  if !coprime
    fl = coprime_base(fl)
  end
  ffl = eltype(fl)[]
  for x = fl
    append!(ffl, collect(keys(factor(x).fac)))
  end
  fl = ffl
  K = base_ring(fl[1])
  r = elem_type(K)[]
  if do_roots == Val{true}
    r = elem_type(K)[roots(x)[1] for x = fl if degree(x) == 1]
  end
  lg = eltype(fl)[k for k = fl if degree(k) > 1]
  if iszero(length(lg))
    if do_roots == Val{true}
      return K, r
    else
      return K
    end
  end

  K, a = number_field(lg[1])#, check = false)
  Ks, nk, mk = collapse_top_layer(K)

  ggl = [map_coefficients(mk, lg[1])]
  ggl[1] = divexact(ggl[1], gen(parent(ggl[1])) - preimage(nk, a))

  for i = 2:length(lg)
    push!(ggl, map_coefficients(mk, lg[i]))
  end
  if do_roots == Val{true}
    R = [mk(x) for x = r]
    push!(R, preimage(nk, a))
    Kst, t = PolynomialRing(Ks, cached = false)
    return _splitting_field(vcat(ggl, [t-y for y in R]), coprime = true, do_roots = Val{true})
  else
    return _splitting_field(ggl, coprime = true, do_roots = Val{false})
  end
end

function Base.:(^)(a::nf_elem, e::UInt)
  b = parent(a)()
  ccall((:nf_elem_pow, libantic), Nothing,
        (Ref{nf_elem}, Ref{nf_elem}, UInt, Ref{AnticNumberField}),
        b, a, e, parent(a))
  return b
end


@doc Markdown.doc"""
    normal_closure(K::AnticNumberField) -> AnticNumberField, NfToNfMor

The normal closure of $K$ together with the embedding map.
"""
function normal_closure(K::AnticNumberField)
  s = splitting_field(K.pol)
  r = roots(K.pol, s)[1]
  return s, hom(K, s, r, check = false)
end

function set_name!(K::AnticNumberField, s::String)
  Nemo.set_special(K, :name => s)
end

function set_name!(K::AnticNumberField)
  s = find_name(K)
  s === nothing || set_name!(K, string(s))
end

################################################################################
#
#  Is linearly disjoint
#
################################################################################

function islinearly_disjoint(K1::AnticNumberField, K2::AnticNumberField)
  if gcd(degree(K1), degree(K2)) == 1
    return true
  end
  d1 = numerator(discriminant(K1.pol))
  d2 = numerator(discriminant(K2.pol))
  if gcd(d1, d2) == 1
    return true
  end
  try
    OK1 = _get_maximal_order(K1)
    OK2 = _get_maximal_order(K2)
    if iscoprime(discriminant(K1), discriminant(K2))
      return true
    end
  catch e
    if !isa(e, AccessorNotSetError)
      rethrow(e)
    end
  end
  f = change_base_ring(K2, K1.pol)
  return isirreducible(f)
end

################################################################################
#
#  more general coercion, field lattice
#
################################################################################

Nemo.iscyclo_type(::NumField) = false

function force_coerce(a::NumField{T}, b::NumFieldElem, throw_error::Type{Val{S}} = Val{true}) where {T, S}
  if Nemo.iscyclo_type(a) && Nemo.iscyclo_type(parent(b))
    return force_coerce_cyclo(a, b, throw_error)::elem_type(a)
  end
  if absolute_degree(parent(b)) <= absolute_degree(a)
    c = find_one_chain(parent(b), a)
    if c !== nothing
      x = b
      for f = c
        @assert parent(x) == domain(f)
        x = f(x)
      end
      return x::elem_type(a)
    end
  end
  if throw_error === Val{true}
    throw(error("no coercion possible"))
  else
    return false
  end
end

@noinline function force_coerce_throwing(a::NumField{T}, b::NumFieldElem) where {T}
  if absolute_degree(parent(b)) <= absolute_degree(a)
    c = find_one_chain(parent(b), a)
    if c !== nothing
      x = b
      for f = c
        @assert parent(x) == domain(f)
        x = f(x)
      end
      return x::elem_type(a)
    else
      throw(error("no coercion possible"))
    end
  else
    throw(error("no coercion possible"))
  end
end

#(large) fields have a list of embeddings from subfields stored (special -> subs)
#this traverses the lattice downwards collecting all chains of embeddings
function collect_all_chains(a::NumField, filter::Function = x->true)
  s = get_special(a, :subs)
  if s === nothing
    return s
  end
  all_chain = Dict{UInt, Array{Any}}(objectid(domain(f)) => [f] for f = s if filter(f))
  if isa(base_field(a), NumField)
    all_chain[objectid(base_field(a))] = [MapFromFunc(x->a(x), base_field(a), a)]
  end
  new_k = Any[domain(f) for f = s]
  while length(new_k) > 0
    k = pop!(new_k)
    s = get_special(k, :subs)
    s === nothing && continue
    for f in s
      if filter(domain(f))
        o = objectid(domain(f))
        if haskey(all_chain, o)
          continue
        end
        @assert !haskey(all_chain, o)
        all_chain[o] = vcat([f], all_chain[objectid(codomain(f))])
        @assert !(o in new_k)
        push!(new_k, domain(f))
        if isa(base_field(domain(f)), NumField)
          b = base_field(domain(f))
          ob = objectid(b)
          if !haskey(all_chain, ob)
            g = MapFromFunc(x->domain(f)(x), b, domain(f))
            all_chain[ob] = vcat([g], all_chain[objectid(domain(f))])
            push!(new_k, b)
          end
        end
      end
    end
  end
  return all_chain
end

#tries to find one chain (array of embeddings) from a -> .. -> t
function find_one_chain(t::NumField, a::NumField)
  s = get_special(a, :subs)
  if s === nothing
    return s
  end
  ot = objectid(t)
  all_chain = Dict{UInt, Array{Any}}(objectid(domain(f)) => [f] for f = s)
  if isa(base_field(a), NumField)
    all_chain[objectid(base_field(a))] = [MapFromFunc(x->a(x), base_field(a), a)]
  end
  new_k = Any[domain(f) for f = s]
  if haskey(all_chain, ot)
    return all_chain[ot]
  end
  new_k = Any[domain(f) for f = s]
  while length(new_k) > 0
    k = pop!(new_k)
    s = get_special(k, :subs)
    s === nothing && continue
    for f in s
      o = objectid(domain(f))
      if o == ot
        return vcat([f], all_chain[objectid(codomain(f))])
      end
      if o in keys(all_chain)
        continue
      end
      @assert !haskey(all_chain, o)
      all_chain[o] = vcat([f], all_chain[objectid(codomain(f))])
      @assert !(o in new_k)
      push!(new_k, domain(f))
      if isa(base_field(domain(f)), NumField)
        b = base_field(domain(f))
        ob = objectid(b)
        if !haskey(all_chain, ob)
          g = MapFromFunc(x->domain(f)(x), b, domain(f))
          all_chain[ob] = vcat([g], all_chain[objectid(domain(f))])
          push!(new_k, b)
        end
        if ob == ot
          return all_chain[ob]
        end
      end
    end
  end
  return nothing
end

@doc Markdown.doc"""
    embed(f::Map{<:NumField, <:NumField})

Registers `f` as a canonical embedding from the domain into the co-domain.
Once this embedding is registered, it cannot be changed.
"""
function embed(f::Map{<:NumField, <:NumField})
  d = domain(f)
  c = codomain(f)
  if c == d
    return
  end
  @assert absolute_degree(d) <= absolute_degree(c)
  cn = find_one_chain(d, c)
  if cn !== nothing
    if issimple(d)
      cgend = force_coerce(c, gen(d))
      if cgend != f(gen(d))
        error("different embedding already installed")
        return
      end
    else
      if any(x->c(x) != f(x), gens(d))
        error("different embedding already installed")
      end
    end
  end
  s = get_special(c, :subs)
  if s === nothing
    s = Any[f]
  else
    push!(s, f)
  end
  set_special(c, :subs => s)
  s = get_special(c, :sub_of)

  if s === nothing
    s = Any[WeakRef(c)]
  else
    push!(s, WeakRef(c))
  end

  set_special(d, :sub_of => s)
end

@doc Markdown.doc"""
    hasembedding(F::NumField, G::NumField) -> Bool

Checks if an embedding from $F$ into $G$ is already known.
"""
function hasembedding(F::NumField, G::NumField)
  if F == G
    return true
  end
  if absolute_degree(G) % absolute_degree(F) != 0
    return false
  end
  cn = find_one_chain(d, c)
  return cn !== nothing
end

#in (small) fields, super fields are stored via WeakRef's
# special -> :sub_of
#this find all superfields registered
function find_all_super(A::NumField, filter::Function = x->true)
  s = get_special(A, :sub_of)
  s === nothing && return Set([A])

  ls = length(s)
  filter!(x->x.value !== nothing, s)
  if length(s) < ls #pruning old superfields
    set_special(A, :sub_of)
  end

  #the gc could(?) run anytime, so even after the pruning above
  #things could get deleted

  all_s = Set([x.value for x = s if x.value !== nothing && filter(x.value)])
  new_s = copy(all_s)
  while length(new_s) > 0
    B = pop!(new_s)
    s = get_special(B, :sub_of)
    s === nothing && continue
    ls = length(s)
    filter!(x->x.value !== nothing, s)
    if length(s) < ls
      set_special(B, :sub_of)
    end
    for x = s
      v = x.value
      if v !== nothing && filter(v)
        push!(new_s, v)
        push!(all_s, v)
      end
    end
  end
  return all_s
end

#finds a common super field for A and B, using the weak-refs
# in special -> :sub_of
function common_super(A::NumField, B::NumField)
  A === B && return A
  if Nemo.iscyclo_type(A) && Nemo.iscyclo_type(B)
    return cyclotomic_field(lcm(get_special(A, :cyclotomic_field), get_special(B, :cyclotomic_field)))[1]
  end

  c = intersect(find_all_super(A), find_all_super(B))
  first = true
  m = nothing
  for C = c
    if first
      m = C
      first = false
    else
      if absolute_degree(C) < absolute_degree(m)
        m = C
      end
    end
  end
  return m
end

function common_super(a::NumFieldElem, b::NumFieldElem)
  C = common_super(parent(a), parent(b))
  if C === nothing
    return C, C
  end
  return C(a), C(b)
end

#tries to find a common parent for all "a" and then calls op on it.
function force_op(op::T, throw_error::Type{Val{S}}, a::NumFieldElem...) where {T <: Function, S}
  C = parent(a[1])
  for b = a
    C = common_super(parent(b), C)
    if C === nothing
      if throw_error === Val{true}
        throw(error("no common parent known"))
      else
        return nothing
      end
    end
  end
  return op(map(C, a)...)
end

@doc Markdown.doc"""
    embedding(k::NumField, K::NumField) -> Map

Assuming $k$ is known to be a subfield of $K$, return the embedding map.
"""
function embedding(k::NumField, K::NumField)
  if issimple(k)
    return hom(k, K, K(gen(k)))
  else
    return hom(k, K, map(K, gens(k)))
  end
end

function force_coerce_cyclo(a::AnticNumberField, b::nf_elem, throw_error::Type{Val{T}} = Val{true}) where {T}
  if iszero(b) 
    return a(0)
  end
#  Base.show_backtrace(stdout, backtrace())
  fa = get_special(a, :cyclo)
  fb = get_special(parent(b), :cyclo)

  if degree(parent(b)) == 2
    b_length = 2
  elseif degree(parent(b)) == 1
    b_length = 1
  else
    b_length = b.elem_length
  end

  # We want to write `b` as an element in `a`.
  # This is possible if and only if `b` can be written as an element
  # in the `fg`-th cyclotomic field, where `fg = gcd(fa, fb)`
  fg = gcd(fa, fb)
  if fg <= 2
    # the code below would not work
    if isrational(b)
      return a(coeff(b, 0))
    elseif throw_error === Val{true}
      throw(error("no coercion possible"))
    else
      return
    end
  end

  ff = parent(parent(b).pol)(b)
  if fg < fb
    # first coerce down from fb to fg
    zb = gen(parent(b))
    q = divexact(fb, fg)
    za = zb^q

    cb = [i for i=1:fb if gcd(i, fb) == 1] # the "conjugates" in the large field
    cg = [[i for i = cb if i % fg == j] for j=1:fg if gcd(j, fg) == 1] #broken into blocks

    #in general one could test first if the evaluation is constant on a block
    #equivalently, if the element is Galois invariant under the fix group of a.
    #the result of the interpolation is supposed to be over Q, so we could
    #do this modulo deg-1-primes as well
    #using a fast(er) interpolation would be nice as well
    #but, this is avoiding matrices, so the complexity is better
    #
    #Idea
    # b is a poly in Qx, evaluating at gen(a)... will produce the conjugates
    # b in a is also a poly, of smaller degree producing the same conjugates
    # so I compute the conjugates from the large field and interpolate them to get
    # the small degree poly
    #actually, since we're using roots of one, we probably should use FFT techniques

    ex = [x[1] for x = cg]
    ky = PolynomialRing(parent(b), cached = false)[1]
    f = interpolate(ky, [(za)^(i) for i=ex],
                        [ff(zb^(i)) for i=ex])
    g = parent(ff)()
    for i=0:length(f)
      c = coeff(f, i)
      if !isrational(c)
        if throw_error === Val{true}
          throw(error("no coercion possible"))
        else
          return
        end
      end
      setcoeff!(g, i, FlintQQ(c))
    end

    ff = g
  end

  # now ff is a polynomial for b w.r.t. the fg-th cyclotomic field
  if fg < fa
    # coerce up from fg to fa
    #so a = p(z) for p in Q(x) and z = gen(parent(b))
    q = divexact(fa, fg)
    c = parent(a.pol)()
    for i=0:degree(ff)
      setcoeff!(c, i*q, coeff(ff, i))
    end
    ff = c
  end

  # now ff is a polynomial for b w.r.t. the fa-th cyclotomic field
  return a(ff)
end

(::FlintRationalField)(a::nf_elem) = (isrational(a) && return coeff(a, 0)) || error("not a rational")
(::FlintIntegerRing)(a::nf_elem) = (isinteger(a) && return numerator(coeff(a, 0))) || error("not an integer")

