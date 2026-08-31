<?php

namespace App\Twig;

use Symfony\Component\HttpFoundation\RequestStack;
use Twig\Loader\FilesystemLoader;
use Twig\Loader\LoaderInterface;
use Twig\Source;

class LocaleAwareLoader implements LoaderInterface
{
    private FilesystemLoader $enLoader;
    private FilesystemLoader $zhLoader;
    private RequestStack $requestStack;

    public function __construct(RequestStack $requestStack, array $paths = [], ?string $rootPath = null)
    {
        $this->requestStack = $requestStack;
        $this->enLoader = new FilesystemLoader([], $rootPath);
        $this->zhLoader = new FilesystemLoader([], $rootPath);
        foreach ($paths as $path) {
            $this->addPath($path);
        }
    }

    public function addPath(string $path, string $namespace = FilesystemLoader::MAIN_NAMESPACE): void
    {
        $this->enLoader->addPath($path, $namespace);
        $zhPath = str_replace('/templates', '/templates_zh', $path);
        if (is_dir($zhPath)) {
            $this->zhLoader->addPath($zhPath, $namespace);
        }
        $this->zhLoader->addPath($path, $namespace);
    }

    public function getSourceContext(string $name): Source
    {
        return $this->loader()->getSourceContext($name);
    }

    public function getCacheKey(string $name): string
    {
        return $this->currentLang() . ':' . $this->loader()->getCacheKey($name);
    }

    public function isFresh(string $name, int $time): bool
    {
        return $this->loader()->isFresh($name, $time);
    }

    public function exists(string $name): bool
    {
        return $this->loader()->exists($name);
    }

    private function loader(): FilesystemLoader
    {
        return $this->currentLang() === 'zh' ? $this->zhLoader : $this->enLoader;
    }

    private function currentLang(): string
    {
        return $this->requestStack->getCurrentRequest()?->cookies->get('domjudge_lang', 'en') ?? 'en';
    }
}
