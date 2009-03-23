######################################################################
# GNU R
#
# Plota uma power law, mostrando a mediana e a media.
######################################################################

# Dados de entrada
a = 2.5
xmin = 1.0
x = (100:800) / 100

##################################################

# Calculos
c = 1 / a
f = function(x) { c * x^(-a)}
p = f(x) #c * x^(-a)
xmed = 2^(1/(a-1)) * xmin
xmean = ((a-1)/(a-2)) * xmin

# Desenho
plot(p ~ x, pch=19, xlab="k", ylab="P(k)", type="l", lwd=3) #, log="xy")
#lines(dnorm(x, 1, 1) ~ x, type="l", col="red", lwd=2, lty=2) # Gauss

lines(c(xmed, xmed), c(0, f(xmed)), lty=2)
lines(c(xmean, xmean), c(0, f(xmean)), lty=2)
text(xmean, f(xmean)+0.03, "média", srt=90);
text(xmed, f(xmed)+0.05, "mediana", srt=90);
print(xmed)
print(xmean)
print(f(6))
